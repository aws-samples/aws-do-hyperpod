#!/bin/bash


CMD="aws eks list-clusters ${ENDPOINT_ARG}"

if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi

eval "$CMD"

