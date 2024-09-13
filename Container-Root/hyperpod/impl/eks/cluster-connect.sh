#!/bin/bash

help(){
	echo ""
	echo "Usage: $0 <cluster_name>"
	echo ""
}

if [ "$1" == "" ]; then
	help
else
	CMD="aws eks update-kubeconfig --name ${1} ${ENDPOINT_ARG}"
	if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
	eval "$CMD"
fi

