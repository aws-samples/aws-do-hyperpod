#!/bin/bash

CMD="kubectl apply -f https://bit.ly/do-htop-daemonset"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "${CMD}"

