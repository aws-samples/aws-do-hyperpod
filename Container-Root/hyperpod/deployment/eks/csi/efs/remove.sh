#!/bin/bash

# Remove example and  EFS CSI from current cluster

kubectl get pod -A | grep efs-pod

export CLUSTER_NAME=$(kubectl config current-context | cut -d '/' -f 2)

./pod-delete.sh

./pvc-delete.sh

FILE_SYSTEM_ID=$(aws resourcegroupstaggingapi get-resources --tag-filters "Key=owner,Values=$CLUSTER_NAME" --query ResourceTagMappingList[].ResourceARN --output text | grep elasticfilesystem | cut -d '/' -f 2)

if [ ! "$FILE_SYSTEM_ID" == "" ]; then

	./sc-delete.sh $FILE_SYSTEM_ID

	./efs-delete.sh $FILE_SYSTEM_ID
else
	echo "File system with owner tag $CLUSTER_NAME not found"
fi

./csi-remove.sh 

