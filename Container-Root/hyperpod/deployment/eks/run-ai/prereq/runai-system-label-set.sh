#!/bin/bash

echo ""
echo "Labeling runai-system nodes ..."

usage() {
	echo ""
	echo "Usage: $0 <node_names>"
	echo ""
	echo "node_names     - space separated list of node names to label as runai-system"
	echo ""
}

if [ "$1" == "" ]; then
	usage
else
	kubectl label nodes $@ node-role.kubernetes.io/runai-system=true --overwrite
fi

echo ""
