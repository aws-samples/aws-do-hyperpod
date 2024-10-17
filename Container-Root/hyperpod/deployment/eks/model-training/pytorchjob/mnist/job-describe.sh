#!/bin/bash

CMD="hyperpod get-job --job-name mnist-cpu"

if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "${CMD}"

