#!/bin/bash


usage(){
	echo ""
	echo "Usage: $0 [eks_cluster_name]"
	echo ""
	echo "eks_cluster_name   - optional name of the EKS cluster to describe"
	echo "                     if no name specified, then current context is used"
	echo ""
	echo "--help             - display usage"
	echo ""
}

if [ "$1" == "--help" ]; then
	usage
elif [ "$1" == "" ]; then
	CLUSTER_NAME=$(kubectl config current-context | cut -d '/' -f 2)
else
	CLUSTER_NAME=$1
fi

CMD="aws eks describe-cluster --name $CLUSTER_NAME"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "${CMD}"

