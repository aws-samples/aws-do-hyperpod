#!/bin/bash

# Load environment variables
source env_vars

echo "Running: envsubst < jumpstart.yaml | kubectl apply -f -"
echo "Creating HyperPod JumpStart Model with Autoscaling and Task Governance..."

envsubst < inference/jumpstart.yaml | kubectl apply -f -