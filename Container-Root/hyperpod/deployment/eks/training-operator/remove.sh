#!/bin/bash

CMD="kubectl delete -k 'github.com/kubeflow/training-operator.git/manifests/overlays/standalone?ref=v1.7.0'"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "${CMD}"

