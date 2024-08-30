#!/bin/bash

source conf/env.conf
source ${CONF}/env_input
source ${CONF}/env_vars

help(){
	echo ""
	echo "Delete specified nodes from current cluster"
	echo ""
	echo "Usage: $0 <node-ids>"
	echo ""
	echo "       node-ids   - space separated list of node ids to delete"
	echo ""
}

if [ "$1" == "" ]; then
	help
else
	echo ""
	echo "Deleting HyperPod node $1 from $IMPL cluster ${HYPERPOD_NAME}: "

	impl/${IMPL}/hyperpod-delete-nodes.sh $@
fi

