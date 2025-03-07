#!/bin/bash

CMD="kubectl delete -f ./pod.yaml"
if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

