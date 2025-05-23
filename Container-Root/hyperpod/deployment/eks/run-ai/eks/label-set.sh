#!/bin/bash

CMD="kubectl label nodes $(kubectl get nodes | grep internal | cut -d ' ' -f 1 | xargs) node-role.kubernetes.io/runai-system=true --overwrite"
if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

