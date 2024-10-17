#!/bin/bash

CMD="hyperpod list-jobs"

if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "${CMD}"

