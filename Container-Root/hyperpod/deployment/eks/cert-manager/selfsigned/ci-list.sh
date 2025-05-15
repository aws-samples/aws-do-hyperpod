#!/bin/bash

# ClusterIssuer description

CMD="kubectl get clusterissuer"
if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

echo ""

