#!/bin/bash

help(){
	echo ""
	echo "$0 - lists cluster nodes with instance type and health status"
	echo "" 
	echo "Usage: $0 [node_name]"
	echo "       node_name - optional, partial or full name of the node to display"
	echo "                   if a partial name is specified that matches more than one node"
	echo "                   then all matching nodes will be displayed"
	echo ""
}

if [ "$1" == "--help" ]; then
	help
else

	node=$1

	shift

	if [ "$node" == "" ]; then
		CMD="kubectl get nodes -L node.kubernetes.io/instance-type -L sagemaker.amazonaws.com/node-health-status $@"
	else
		CMD="kubectl get nodes -L node.kubernetes.io/instance-type -L sagemaker.amazonaws.com/node-health-status  $@ | grep -E \"NODE-HEALTH-STATUS|$node\""
	fi

	if [ "${VERBOSE}" == "true" ]; then
		echo ""
		echo "${CMD}"
		echo ""
	fi

	if [ ! "${DRY_RUN}" == "true" ]; then
		eval "${CMD}"
	fi

fi


