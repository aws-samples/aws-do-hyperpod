#!/bin/bash

pushd ../../..
EKS_CLUSTER_NAME=$(./hyperpod-describe.sh | tail -n +6 | jq -r .Orchestrator.Eks.ClusterArn | cut -d '/' -f 2)
popd

CMD="aws eks create-addon --addon-name amazon-cloudwatch-observability --cluster-name $EKS_CLUSTER_NAME"

if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "${CMD}"

