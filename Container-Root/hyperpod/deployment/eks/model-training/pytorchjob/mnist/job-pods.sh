#!/bin/bash

CMD="hyperpod list-pods --job-name mnist-cpu"

if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "${CMD}"

