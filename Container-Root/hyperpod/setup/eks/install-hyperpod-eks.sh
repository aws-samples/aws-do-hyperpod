#!/bin/bash

# Create destination
mkdir -p /hyperpod/impl/eks/src
pushd /hyperpod/impl/eks/src

# Download assets

## cfn
mkdir cfn
curl 'https://raw.githubusercontent.com/aws-samples/awsome-distributed-training/main/1.architectures/7.sagemaker-hyperpod-eks/hyperpod-eks-full-stack.yaml' --output cfn/hyperpod-eks-full-stack.yaml

## scripts
mkdir scripts
#curl 'https://raw.githubusercontent.com/aws-samples/awsome-distributed-training/main/1.architectures/7.sagemaker-hyperpod-eks/create_config.sh' --output scripts/create_config.sh
chmod +x scripts/*.sh


## lifecyclescripts
mkdir lifecyclescripts
curl 'https://raw.githubusercontent.com/aws-samples/awsome-distributed-training/main/1.architectures/7.sagemaker-hyperpod-eks/LifecycleScripts/base-config/on_create.sh' --output lifecyclescripts/on_create.sh
chmod +x lifecyclescripts/*.sh


## helm dependencies
git clone https://github.com/aws/sagemaker-hyperpod-cli.git

## hyperpod cli
pushd sagemaker-hyperpod-cli
pip install .

