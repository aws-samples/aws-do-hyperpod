#!/bin/bash

# Delete cluster issuer

CMD="kubectl delete -f ./clusterissuer.yaml"
if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

echo ""

