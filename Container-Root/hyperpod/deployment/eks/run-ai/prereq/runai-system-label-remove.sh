#!/bin/bash

echo ""
echo "Removing runai-system label ..."

usage() {
	echo ""
	echo "Usage: $0 <node_names>"
	echo ""
	echo "node_names     - space separated list of node names to clear the runai-system label from"
	echo ""
}

if [ "$1" == "" ]; then
	usage
else
	CMD="kubectl label nodes $@ node-role.kubernetes.io/runai-system-"
fi

echo ""
