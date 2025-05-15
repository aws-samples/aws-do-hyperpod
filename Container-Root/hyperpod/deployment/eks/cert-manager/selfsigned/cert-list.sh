#!/bin/bash

# List certificates

CMD="kubectl get certificate"
if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

echo ""

