#!/bin/bash

CMD="hyperpod cancel-job --job-name mnist-cpu"

if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "${CMD}"

