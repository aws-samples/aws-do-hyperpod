#!/bin/bash

echo "Running: envsubst < deploy_s3_inference.yaml | kubectl apply -f -"

echo "Creating HyperPod Inference Operator Job for training DeepSeek 15B parameter model..."

echo ""

envsubst < inference/deploy_s3_inference.yaml | kubectl apply -f -