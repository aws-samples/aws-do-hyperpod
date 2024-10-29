#!/bin/bash


CMD="kubectl -n amazon-cloudwatch get pods"

if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "${CMD}"

