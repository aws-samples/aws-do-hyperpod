#!/bin/bash

echo "Running: kubectl delete -f training/hpto_5b.yaml "

echo "Deleting HyperPod PytorchJob for training Llama3 5B parameter model..."

echo ""

kubectl delete -f training/hpto_5b.yaml 