# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

import datetime
import functools
import math
import re
import time

import numpy as np
import torch
from torch import optim
import torch.distributed as dist
import torch.utils.data

import transformers
from transformers import AutoModelForCausalLM, AutoTokenizer
from datasets import load_dataset

from torch.distributed.fsdp import FullyShardedDataParallel as FSDP
from torch.distributed.fsdp import MixedPrecision
from torch.distributed.fsdp import ShardingStrategy
from torch.distributed.fsdp import CPUOffload
from torch.distributed.fsdp import StateDictType, FullStateDictConfig
from torch.distributed.fsdp.wrap import size_based_auto_wrap_policy, transformer_auto_wrap_policy
from torch.utils.data import DataLoader

from model_utils.concat_dataset import ConcatTokensDataset
from model_utils.train_utils import (get_model_config, 
                                   compute_num_params,
                                   get_transformer_layer,
                                   get_sharding_strategy,
                                   get_backward_fetch_policy,
                                   apply_activation_checkpoint,
                                   get_param_groups_by_weight_decay,
                                   get_logger,
                                   get_learning_rate_scheduler,
                                   create_streaming_dataloader)
from model_utils.checkpoint import save_checkpoint, load_checkpoint
from model_utils.arguments import parse_args


import logging
import sys
import mlflow
import mlflow.pytorch
import mlflow.transformers

logging.basicConfig(format="%(asctime)s [%(levelname)s] %(name)s: %(message)s", level=logging.INFO, stream=sys.stdout)

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

arn = "arn:aws:sagemaker:us-east-1:011528295005:mlflow-tracking-server/hyperpod-ts-demo"
mlflow.set_tracking_uri(arn)


def eval_model(model, dataloader, num_batches):
    """Eval step."""
    model = model.eval()
    n_batches = 0
    loss = 0.0

    with torch.no_grad():
        for batch_idx, input_data in enumerate(dataloader):
            if batch_idx >= num_batches:
                break

            loss += model(input_ids=input_data, attention_mask=None, labels=input_data)["loss"]
            n_batches += 1

    if n_batches > 0:
        detached_loss = loss.detach()
        torch.distributed.all_reduce(detached_loss)
        loss = detached_loss.item() / dist.get_world_size()
        loss /= n_batches
        ppl = math.exp(loss)
    else:
        loss = -1.0
        ppl = -1.0

    return loss, ppl

def train(
        model,
        optimizer,
        train_dataloader,
        val_dataloader,
        lr_scheduler,
        model_config,
        num_params,
        args,
        global_rank,
        world_size,
        total_steps=0,
        start_batch_index=0
    ):
    model.train()
    for index in range(args.epochs):
        for batch_idx, input_data in enumerate(train_dataloader):
            if batch_idx < start_batch_index:
                continue
            optimizer.zero_grad(set_to_none=True)
            step_start = time.time()
            loss = model(input_ids=input_data, attention_mask=None, labels=input_data)["loss"]
            loss.backward()
            model.clip_grad_norm_(args.grad_clip)
            optimizer.step()
            lr_scheduler.step()
            total_steps += 1
            loss_metric = loss.item()
            step_time = time.time() - step_start
            sample_processed = input_data.shape[0] * world_size
            throughput = sample_processed / step_time
            loss_scalar = loss.item()
            current_lr = lr_scheduler.get_lr()
            if global_rank==0 and batch_idx%args.logging_freq==0:
                logger.info(
                    "Batch %d Loss: %.5f, Speed: %.2f samples/sec, lr: %.6f",  # pylint: disable=line-too-long
                    batch_idx,
                    loss_scalar,
                    throughput,
                    current_lr,
                )
                # Log training metrics to MLflow
                mlflow.log_metric("train_loss", loss_scalar, step=total_steps)
                mlflow.log_metric("learning_rate", current_lr, step=total_steps)
                mlflow.log_metric("throughput_samples_per_sec", throughput, step=total_steps)
            if args.validation_freq and not total_steps % args.validation_freq:
                val_loss, val_ppl = eval_model(
                    model, val_dataloader, args.validation_batches
                )
                model = model.train()
                if global_rank == 0:
                    logger.info(
                            "Batch %d Validation loss: %s",
                            batch_idx,
                            val_loss,
                        )
                    # Log validation metrics to MLflow
                    mlflow.log_metric("val_loss", val_loss, step=total_steps)
                    mlflow.log_metric("val_perplexity", val_ppl, step=total_steps)
            if args.checkpoint_dir and not total_steps % args.checkpoint_freq:
                user_content = {
                    "cli_args": args.__dict__,
                    "num_params": num_params,
                    "total_steps": total_steps,
                    "model_config": model_config,
                    "start_batch_index": batch_idx + 1,
                }
                sub_dir = f"{args.model_type}-{total_steps}steps"

                save_checkpoint(
                    model,
                    optimizer,
                    lr_scheduler,
                    user_content,
                    args.checkpoint_dir,
                    sub_dir,
                )
                
                # Optional: Register intermediate model checkpoints
                if args.register_checkpoints:
                    # All ranks need to participate in FSDP state_dict operations
                    # but only rank 0 will actually register the model
                    try:
                        if global_rank == 0:
                            checkpoint_model_name = f"{args.model_type.replace('_', '-')}-checkpoint-{total_steps}steps"
                            logger.info(f"Registering checkpoint model '{checkpoint_model_name}'...")
                        
                        # Get the model state dict - ALL RANKS must participate
                        save_policy = FullStateDictConfig(offload_to_cpu=True, rank0_only=True)
                        with FSDP.state_dict_type(model, StateDictType.FULL_STATE_DICT, save_policy):
                            checkpoint_state_dict = model.state_dict()
                        
                        # Only rank 0 logs and registers the model
                        if global_rank == 0:
                            import tempfile
                            import os
                            
                            with tempfile.TemporaryDirectory() as temp_dir:
                                # Save the checkpoint model in Hugging Face format
                                checkpoint_save_path = os.path.join(temp_dir, "checkpoint_model")
                                os.makedirs(checkpoint_save_path, exist_ok=True)
                                
                                # Create a new model instance from config and load the checkpoint weights
                                checkpoint_model = AutoModelForCausalLM.from_config(model_config)
                                checkpoint_model.load_state_dict(checkpoint_state_dict)
                                
                                # Save the checkpoint model in Hugging Face format
                                checkpoint_model.save_pretrained(checkpoint_save_path, safe_serialization=True)
                                
                                # Load tokenizer for the checkpoint model
                                tokenizer = AutoTokenizer.from_pretrained(args.tokenizer)
                                tokenizer.save_pretrained(checkpoint_save_path)
                                
                                # Use MLflow transformers integration for checkpoint registration
                                from mlflow.models import infer_signature
                                
                                # Create model signature for MLflow
                                signature = infer_signature(
                                    model_input="What is the capital of France?",
                                    model_output="The capital of France is Paris.",
                                    params={
                                        "max_new_tokens": 50,
                                        "temperature": 0.7,
                                        "top_p": 0.9
                                    }
                                )
                                
                                # Register the checkpoint model using MLflow transformers
                                mlflow.transformers.log_model(
                                    transformers_model={
                                        "model": checkpoint_model,
                                        "tokenizer": tokenizer
                                    },
                                    name=f"checkpoint-{total_steps}",  # Use name instead of artifact_path
                                    signature=signature,
                                    registered_model_name=checkpoint_model_name,
                                    task="text-generation",
                                    model_config={
                                        "model_type": args.model_type,
                                        "num_parameters": int(num_params),  # Convert to regular int
                                        "training_steps": int(total_steps),  # Convert to regular int
                                        "checkpoint": True,
                                        "sharding_strategy": args.sharding_strategy,
                                        "world_size": int(world_size),  # Convert to regular int
                                        "max_new_tokens": 50,
                                        "temperature": 0.7,
                                        "top_p": 0.9
                                    }
                                )
                            
                            logger.info(f"Successfully registered checkpoint model '{checkpoint_model_name}'")
                    except Exception as e:
                        if global_rank == 0:
                            logger.error(f"Failed to register checkpoint model: {str(e)}")
            if total_steps >= args.max_steps:
                break
            

def main(args):
    dist.init_process_group()
    global_rank = dist.get_rank()
    device = global_rank % torch.cuda.device_count()
    world_size = dist.get_world_size()
    
    # Initialize MLflow experiment (only on rank 0)
    if global_rank == 0:
        mlflow.set_experiment("fsdp-training")
        mlflow.start_run()
        # Log hyperparameters
        mlflow.log_params({
            "model_type": args.model_type,
            "epochs": args.epochs,
            "train_batch_size": args.train_batch_size,
            "lr": args.lr,
            "weight_decay": args.weight_decay,
            "sharding_strategy": args.sharding_strategy,
            "world_size": world_size,
            "bf16": args.bf16,
            "activation_checkpointing": args.activation_checkpointing,
            "cpu_offload": args.cpu_offload,
            "register_model": args.register_model,
            "register_checkpoints": args.register_checkpoints,
            "model_name": args.model_name if args.model_name else f"{args.model_type}-fsdp-model"
        })
    
    if args.bf16:
        dtype = torch.bfloat16
    else:
        dtype = torch.get_default_dtype()
    
    model_config = get_model_config(args)
    if global_rank == 0:
        logger.info(
            "Creating Model"
        )
    # Instantiate model on CPU on rank=0 only to prevent CPU OOM
    # (e.g. 70B * 4 bytes * 8 processes > 2T RAM available on P5)
    if global_rank == 0:
        model = AutoModelForCausalLM.from_config(model_config)
    else:
        with torch.device("meta"):
            # Instantiating model on `meta` device doesn't consume CPU memory,
            # but requires specifing `param_init_fn=...`
            # and `sync_module_states=True` in FSDP c-tor.
            model = AutoModelForCausalLM.from_config(model_config)
    
    num_params = compute_num_params(model)
    if global_rank == 0:
        logger.info(
            "Created model with total parameters: %d (%.2f B)", num_params, num_params * 1e-9
        )
    transformer_layer = get_transformer_layer(args.model_type)

    gpt_auto_wrap_policy = functools.partial(
        transformer_auto_wrap_policy,
        transformer_layer_cls={
            transformer_layer,
        },
    )

    torch.cuda.set_device(device)
    mixed_precision_policy = MixedPrecision(
        param_dtype=dtype, reduce_dtype=dtype, buffer_dtype=dtype
    )

    if args.sharding_strategy=="full":
        sharding_strategy = ShardingStrategy.FULL_SHARD
    elif args.sharding_strategy=="hybrid":
        sharding_strategy = ShardingStrategy.HYBRID_SHARD
    else:
        raise NotImplementedError("Available sharding strategies are full and hybrid")
    
    if args.cpu_offload == 1:
        cpu_offload = CPUOffload(offload_params=True)
    else: 
        cpu_offload = None

    model = FSDP(
        model,
        auto_wrap_policy=gpt_auto_wrap_policy,
        mixed_precision=mixed_precision_policy,
        limit_all_gathers=args.limit_all_gathers,
        device_id=torch.cuda.current_device(),
        use_orig_params=False,
        sharding_strategy=sharding_strategy,
        cpu_offload=cpu_offload,
        sync_module_states=True,
        param_init_fn=(lambda module: module.to_empty(device=torch.device("cuda"), recurse=False))
        if global_rank != 0 else None,
    )

    if global_rank == 0:
        logger.info("Wrapped model with FSDP")

    if args.activation_checkpointing > 0:
        apply_activation_checkpoint(args, model=model)

    if args.offload_activations > 0:
        from torch.distributed.algorithms._checkpoint.checkpoint_wrapper import offload_wrapper

        model = offload_wrapper(model)

    param_groups = get_param_groups_by_weight_decay(model)

    optimizer = optim.AdamW(
        param_groups, betas=(args.beta1, args.beta2), lr=args.lr, weight_decay=args.weight_decay
    )

    if global_rank == 0:
        logger.info("Created optimizer")

    lr_scheduler = get_learning_rate_scheduler(optimizer, args)

    if args.resume_from_checkpoint:
        (
            model,
            optimizer,
            lr_scheduler,
            total_steps,
            start_batch_index,
        ) = load_checkpoint(model, 
                            optimizer, 
                            lr_scheduler, 
                            args.resume_from_checkpoint, 
                            args.model_type,
                            device)
    else:
        total_steps = 0
        start_batch_index = 0
    
    train_dataloader = create_streaming_dataloader(args.dataset, 
                                                   args.tokenizer, 
                                                   name=args.dataset_config_name, 
                                                   batch_size=args.train_batch_size, 
                                                   split='train')
    
    val_dataloader = create_streaming_dataloader(args.dataset, 
                                                  args.tokenizer, 
                                                  name=args.dataset_config_name, 
                                                  batch_size=args.train_batch_size, 
                                                  split='validation')
    
    train(model, 
          optimizer, 
          train_dataloader,
          val_dataloader,
          lr_scheduler, 
          model_config, 
          num_params, 
          args, 
          global_rank, 
          world_size,
          total_steps,
          start_batch_index)
  
    # Register model with MLflow Model Registry
    # All ranks must participate in FSDP operations, but only rank 0 registers
    if args.register_model:
        try:
            if global_rank == 0:
                # Create a model name based on arguments or default
                model_name = args.model_name if args.model_name else f"{args.model_type.replace('_', '-')}-fsdp-model"
                logger.info(f"Registering model '{model_name}' in MLflow Model Registry...")
            
            # Get the model state dict in a format that can be saved
            # Configure FSDP to return full state dict on rank 0 - ALL RANKS participate
            save_policy = FullStateDictConfig(offload_to_cpu=True, rank0_only=True)
            with FSDP.state_dict_type(model, StateDictType.FULL_STATE_DICT, save_policy):
                model_state_dict = model.state_dict()
            
            # Only rank 0 logs and registers the model
            if global_rank == 0:
                import tempfile
                import os
                
                with tempfile.TemporaryDirectory() as temp_dir:
                    # Save the model in Hugging Face format for better MLflow compatibility
                    model_save_path = os.path.join(temp_dir, "model")
                    os.makedirs(model_save_path, exist_ok=True)
                    
                    # Create a new model instance from config and load the trained weights
                    # This creates a proper Hugging Face model that MLflow can handle
                    clean_model = AutoModelForCausalLM.from_config(model_config)
                    clean_model.load_state_dict(model_state_dict)
                    
                    # Save the model in Hugging Face format
                    clean_model.save_pretrained(model_save_path, safe_serialization=True)
                    
                    # Load tokenizer for the model
                    tokenizer = AutoTokenizer.from_pretrained(args.tokenizer)
                    tokenizer.save_pretrained(model_save_path)
                    
                    # Use MLflow transformers integration for proper model registration
                    from mlflow.models import infer_signature
                    
                    # Create model signature for MLflow
                    signature = infer_signature(
                        model_input="What is the capital of France?",
                        model_output="The capital of France is Paris.",
                        params={
                            "max_new_tokens": 50,
                            "temperature": 0.7,
                            "top_p": 0.9
                        }
                    )
                    
                    # Register the model using MLflow transformers
                    mlflow.transformers.log_model(
                        transformers_model={
                            "model": clean_model,
                            "tokenizer": tokenizer
                        },
                        name="model",  # Use name instead of artifact_path
                        signature=signature,
                        registered_model_name=model_name,
                        task="text-generation",
                        model_config={
                            "model_type": args.model_type,
                            "num_parameters": int(num_params),  # Convert to regular int
                            "training_steps": int(total_steps),  # Convert to regular int
                            "sharding_strategy": args.sharding_strategy,
                            "world_size": int(world_size),  # Convert to regular int
                            "max_new_tokens": 50,
                            "temperature": 0.7,
                            "top_p": 0.9
                        }
                    )
                
                logger.info(f"Model registered successfully as '{model_name}' in MLflow Model Registry")
            
        except Exception as e:
            if global_rank == 0:
                logger.error(f"Failed to register model: {str(e)}")
                # Continue execution even if model registration fails
    
    # End MLflow run (only on rank 0)
    if global_rank == 0:
        mlflow.end_run()
    
    dist.destroy_process_group()

if __name__ == "__main__":
    args, _ = parse_args()
    main(args)
