#!/bin/bash

CMD="hyperpod start-job --config-file ./mnist-cpu.yaml"

if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "${CMD}"

