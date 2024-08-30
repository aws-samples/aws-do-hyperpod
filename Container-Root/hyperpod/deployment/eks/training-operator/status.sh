#!/bin/bash

CMD="kubectl get pods -n kubeflow"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "${CMD}"

