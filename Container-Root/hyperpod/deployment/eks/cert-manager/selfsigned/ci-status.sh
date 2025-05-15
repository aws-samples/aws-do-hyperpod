#!/bin/bash

# ClusterIssuer description

CMD="kubectl describe clusterissuer selfsigned"
if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

echo ""

