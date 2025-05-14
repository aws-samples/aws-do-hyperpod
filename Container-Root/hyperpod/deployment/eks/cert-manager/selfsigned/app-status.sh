#!/bin/bash

# Show status of certificate

CMD="kubectl get pods,deployments,services"
if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

echo ""

