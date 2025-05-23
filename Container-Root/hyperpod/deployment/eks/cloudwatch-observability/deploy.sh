#!/bin/bash

EKS_CLUSTER_NAME=$(kubectl config current-context | cut -d '/' -f 2)

CMD="aws eks create-addon --addon-name amazon-cloudwatch-observability --cluster-name $EKS_CLUSTER_NAME"

if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "${CMD}"

