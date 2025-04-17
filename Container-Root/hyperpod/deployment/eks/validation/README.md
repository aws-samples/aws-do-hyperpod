# Validation tests for SageMaker HyperPod EKS

This document provides simple examples of running distributed model training on CPU or GPU using the EKS interface of SageMaker HyperPod. It also provides examples of running model inference on CPU or GPU. These examples can be used for validation testing of HyperPod EKS clusters or as a getting-started guide for implementation of larger-scale distributed training or inference.

## Prerequisites

The distributed training examples are dependent on the Kubeflow Training Operator, which is installed by default on HyperPod EKS clusters.
If needed, the Kubeflow Training Operator can be installed using the scripts provided [here](https://github.com/aws-samples/aws-do-eks/tree/main/Container-Root/eks/deployment/kubeflow/training-operator) or by executing the following command block:

```sh
git clone https://github.com/aws-samples/aws-do-eks
cd aws-do-eks/Container-Root/eks/deployment/kubeflow/training-operator
./deploy.sh
```

The GPU examples are dependent on the NVIDIA Device Plugin, which is installed by default on HyperPod EKS clusters.
If needed, the NVIDIA Device Plugin can be installed using the scripts provided [here](https://github.com/aws-samples/aws-do-eks/tree/main/Container-Root/eks/deployment/nvidia-device-plugin) or by executing the following command block:

```sh
git clone https://github.com/aws-samples/aws-do-eks
cd aws-do-eks/Container-Root/eks/deployment/nvidia-device-plugin
./deploy.sh
```

## Distributed model training

### CPU

A simple distributed model training example on CPU using a small imagenet dataset and kubeflow training operator can be launched with the following command:

```sh
kubectl apply -f https://bit.ly/imagenet-cpu
```

### GPU

The same example can be launched on GPUs by executing the following command:

```sh
kubectl apply -f https://bit.ly/imagenet-gpu
```

## Model inference

### CPU

A simple model inference example of serving a BERT model for question answering on CPU, using FastAPI and a test pod which sends CURL requests to the model can be launched with the following command: 

```sh
kubectl apply -f https://bit.ly/simple-inf-cpu
```

### GPU

The same inference example can be launched on GPU by executing the following command:

```sh
kubectl apply -f https://bit.ly/simple-inf-gpu
```

In this case the example uses several test containers in order to generate a noticeable load on the GPU.


