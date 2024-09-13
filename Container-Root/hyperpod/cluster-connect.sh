#!/bin/bash

source ./conf/env.conf
source ${CONF}/env_input

usage(){
	echo ""
	echo "Usage: $0 <cluster_name>"
	echo ""
}

if [ "$1" == "" ]; then
	help
else
	echo ""
	echo "Connecting to $IMPL cluster: $1 "

	impl/${IMPL}/cluster-connect.sh $1
fi
