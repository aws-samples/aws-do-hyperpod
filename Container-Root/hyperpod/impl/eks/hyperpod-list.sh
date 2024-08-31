#!/bin/bash


CMD="aws sagemaker list-clusters ${ENDPOINT_ARG}"

if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi

eval "$CMD"

