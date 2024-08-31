#!/bin/bash

if [ ! "$1" == "" ]; then HYPERPOD_NAME=$1; fi

CMD="aws sagemaker list-clusters ${ENDPOINT_ARG} | grep -B 2 -A 3 ${HYPERPOD_NAME}"

if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi

eval "$CMD"

