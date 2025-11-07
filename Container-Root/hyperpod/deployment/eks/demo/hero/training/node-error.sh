#!/bin/bash
export NODE=$(kubectl get pods -n hyperpod-ns-training-team -l HPJob=llama3-2-1b-fsdp-hpto -o jsonpath='{.items[*].spec.nodeName}' | tr ' ' '\n' | shuf -n 1)

if [ -z "$NODE" ]; then
  echo "No GPU nodes found!"
  exit 1
fi

echo "Selected GPU node: $NODE"
kubectl label node $NODE \
  sagemaker.amazonaws.com/node-health-status=UnschedulablePendingReboot \
  --overwrite=true
