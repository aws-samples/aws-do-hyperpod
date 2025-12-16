#!/bin/bash

echo "Running: envsubst < training/hpto_1b.yaml | kubectl apply -f -"

echo "Creating HyperPod PytorchJob for training Llama3.2 1B parameter model..."

echo ""

envsubst < training/hpto_1b.yaml | kubectl apply -f -