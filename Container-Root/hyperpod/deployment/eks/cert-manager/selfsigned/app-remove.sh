#!/bin/bash

# Show status of certificate

CMD="kubectl delete -f ./selfsigned-app.yaml"
if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

echo ""

