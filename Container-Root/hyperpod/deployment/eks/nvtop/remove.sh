#!/bin/bash

CMD="kubectl delete -f https://bit.ly/do-nvtop-daemonset"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "${CMD}"

