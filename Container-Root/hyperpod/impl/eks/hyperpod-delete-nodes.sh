#!/bin/bash

# Delete HyperPod Cluster
if [ "$1" == "" ]; then 
	echo ""
	echo "At least one node-id must be specified"
	echo ""
else
	echo ""
	echo "Deleting HyperPod nodes from cluster: $HYPERPOD_NAME"
	./hyperpod-status.sh ${HYPERPOD_NAME}
	if [ "$?" == "0" ]; then
    		CMD="aws sagemaker delete-cluster-nodes --cluster-name ${HYPERPOD_NAME} ${ENDPOINT_ARG} --node-ids $@"
    		if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
    		eval "$CMD"
	else
    		echo "HyperPod cluster $HYPERPOD_NAME does not exist"
	fi

    if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
    eval "$CMD"

fi


