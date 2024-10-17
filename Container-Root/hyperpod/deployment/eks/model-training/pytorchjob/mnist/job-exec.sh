#!/bin/bash

usage(){
	echo ""
	echo "Usage: $0 [worker_index] [command]"
	echo ""
	echo "    worker_index - 0,1,etc the worker number to exec into"
	echo "    command      - bash command to execute"
	echo ""	
}

if [ "$1" == "" ]; then
	usage
else

	if [ "$2" == "" ]; then
		num=0
	else
		num=$1
		shift
	fi

	EXEC=$@

	CMD="hyperpod exec --job-name mnist-cpu --pod mnist-cpu-worker-$num $EXEC"

	if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
	eval "${CMD}"
fi
