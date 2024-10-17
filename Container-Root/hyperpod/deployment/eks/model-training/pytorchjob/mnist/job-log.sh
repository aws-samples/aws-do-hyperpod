#!/bin/bash

if [ "$1" == "" ]; then
	num=0
else
	num=$1
fi

CMD="hyperpod get-log --job-name mnist-cpu --pod mnist-cpu-worker-$num"

if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "${CMD}"

