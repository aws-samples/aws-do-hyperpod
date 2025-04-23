# Validation tests for SageMaker HyperPod EKS

This document provides simple examples of running distributed model training on CPU or GPU using the EKS interface of SageMaker HyperPod. It also provides examples of running model inference on CPU or GPU. These examples can be used for validation testing of HyperPod EKS clusters or as a getting-started guide for implementation of larger-scale distributed training or inference.

To run an example, simply copy the `kubectl apply` command from the desired section below. To check status, use `kubectl get pods`, To see logs, use `kubectl logs -f <desired pod name>`, and to stop a run, use the same as the initial command, replacing the `apply` keyword with `delete`, e.g. `kubectl delete -f <url>`.

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

Expected status:
```txt
NAME                        READY   STATUS    RESTARTS   AGE
etcd-cpu-5f8bfdd476-b4mjk   1/1     Running   0          6s
imagenet-cpu-worker-0       1/1     Running   0          6s
imagenet-cpu-worker-1       1/1     Running   0          6s
```

### GPU

The same example can be launched on GPUs by executing the following command:

```sh
kubectl apply -f https://bit.ly/imagenet-gpu
```

Expected status:
```txt
NAME                        READY   STATUS    RESTARTS   AGE
etcd-gpu-84f899599b-t7kp8   1/1     Running   0          5s
imagenet-gpu-worker-0       1/1     Running   0          5s
imagenet-gpu-worker-1       1/1     Running   0          5s
```

## Model inference

### CPU

A simple model inference example of serving a BERT model for question answering on CPU, using FastAPI and a test pod which sends CURL requests to the model can be launched with the following command: 

```sh
kubectl apply -f https://bit.ly/simple-inf-cpu
```

Expected status:
```txt
NAME                              READY   STATUS    RESTARTS   AGE
curl-inf-cpu-5c96667459-9n6gb     1/1     Running   0          2m14s
simple-inf-cpu-77985f46bc-r45fg   1/1     Running   0          2m14s
```

### GPU

The same inference example can be launched on GPU by executing the following command:

```sh
kubectl apply -f https://bit.ly/simple-inf-gpu
```

Expected status:
```txt
NAME                              READY   STATUS    RESTARTS   AGE
curl-inf-gpu-54d8ffd8cc-fhwmt     1/1     Running   0          60s
curl-inf-gpu-54d8ffd8cc-mt7m9     1/1     Running   0          60s
curl-inf-gpu-54d8ffd8cc-qzh8q     1/1     Running   0          60s
curl-inf-gpu-54d8ffd8cc-v25cj     1/1     Running   0          60s
curl-inf-gpu-54d8ffd8cc-xm94j     1/1     Running   0          60s
simple-inf-gpu-5bb97f984b-zhnlr   1/1     Running   0          61s
```

In this case the example uses five test containers in order to generate a noticeable load on the GPU.


