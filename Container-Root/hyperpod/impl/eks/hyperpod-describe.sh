#!/bin/bash

if [ ! "$1" == "" ]; then HYPERPOD_NAME=$1; fi

CMD="aws sagemaker describe-cluster --cluster-name ${HYPERPOD_NAME} ${ENDPOINT_ARG}"

if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi

eval "$CMD"

