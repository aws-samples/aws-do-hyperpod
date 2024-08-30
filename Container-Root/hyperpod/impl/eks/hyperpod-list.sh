#!/bin/bash


CMD="aws sagemaker list-clusters"

if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi

eval "$CMD"

