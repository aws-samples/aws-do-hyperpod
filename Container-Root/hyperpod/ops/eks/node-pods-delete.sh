#!/bin/bash

help(){
	echo ""
	echo "Usage: $0 <node_name> [--force]"
        echo "       Deletes all pods from specified node"
	echo ""
	echo "       node_name - required, name of the node to delete pods from,"
	echo "                   a unique substring from the node name works as well"
	echo "                   if the unique string matches more than one node, then"
	echo "                   pods from all matching nodes will be deleted"
	echo "       --force   - optionally, do not wait for the pods to terminate gracefully"
	echo ""
}

if [ "$1" == "" ]; then
	help
else

	node=$1

	echo ""
	echo "Deleting pods from node(s):"
	kubectl get nodes | grep $node | cut -d ' ' -f 1
	echo ""

	if [ "$2" == "--force" ]; then
		force="--force"
	fi

	pods=($(kubectl get pods -A -o wide | grep $node | awk '{print $1,$2}'))
        i=0
        len=${#pods[@]}
	while [ $i -lt $len ]; do
		ns=${pods[$i]}
		pod=${pods[$((i+1))]}
		CMD="kubectl -n $ns delete pod $pod $force"
		echo "$CMD"
		eval "$CMD"
		i=$((i+2))
	done

fi

