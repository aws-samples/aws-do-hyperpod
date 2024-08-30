#!/bin/bash

help(){
	echo ""
	echo "Usage: $0 <node_name>"
        echo "       Cordons the specified node(s). No new pods are scheduled on cordoned nodes""
	echo ""
	echo "       node_name - required, partial or full name of the node to cordon"
	echo "                   if a partial name is specified that matches more than one node"
	echo "                   then all matching nodes will be cordoned"
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
		CMD="kubectl cordon $node"
		echo "$CMD"
		eval "$CMD"
		i=$((i+1))
	done

fi
	
