#!/bin/bash

CMD="kubectl delete -f ./pvc.yaml"
if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

