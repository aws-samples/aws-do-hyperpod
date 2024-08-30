#!/bin/bash

help(){
	echo ""
	echo "This command runs nvidia-smi in a container on a specified node in your cluster"
	echo ""
	echo "Usage: $0 <node_name> [nvidia-smi-args]"
	echo ""
}

if [ "$1" == "" ]; then
	help
else
	node_name=$1
	pod_name=${node_name:-4}
	shift
	CMD="kubectl run -it --rm $pod_name --image iankoulski/do-nvtop:latest --overrides='{\"apiVersion\": \"v1\", \"spec\": {\"nodeSelector\": { \"kubernetes.io/hostname\": \"$node_name\" }}}' --command -- watch nvidia-smi $@"
	if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
	eval "$CMD"
fi
