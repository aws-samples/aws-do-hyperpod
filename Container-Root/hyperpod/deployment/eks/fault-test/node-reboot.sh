#!/bin/bash

help(){
	echo ""
	echo "Usage: $0 <node_name>"
	echo "       node_name - required, partial or full name of the node to label for reboot"
	echo "                   if a partial name is specified that matches more than one node"
	echo "                   then all matching nodes will be labeled for reboot"
	echo ""
}

if [ "$1" == "" ]; then
	help
else

	node=$1

	echo ""
	nodes=($(kubectl get nodes | grep $node | cut -d ' ' -f 1))
	i=0
	len=${#nodes[@]}
	while [ $i -lt $len ]; do
		node=${nodes[$i]}
		CMD="kubectl label nodes $node sagemaker.amazonaws.com/node-health-status=UnschedulablePendingReboot --overwrite"
		echo "$CMD"
		eval "$CMD"
		i=$((i+1))
	done

fi
	
