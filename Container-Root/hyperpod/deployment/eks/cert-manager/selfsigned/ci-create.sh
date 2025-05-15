#!/bin/bash

# Create cluster issuer

CMD="kubectl apply -f ./clusterissuer.yaml"
if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

echo ""

