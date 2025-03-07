#!/bin/bash

# Reference: https://www.eksworkshop.com/docs/fundamentals/storage/efs/efs-csi-driver

# Get cluster name from current context
CLUSTER_NAME=$(kubectl config current-context | cut -d '/' -f 2)

echo ""
echo "Removing aws-efs-csi-driver addon from $CLUSTER_NAME ..."

CMD="aws eks delete-addon --cluster-name $CLUSTER_NAME --addon-name aws-efs-csi-driver"
if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

CMD="aws eks wait addon-deleted --cluster-name $CLUSTER_NAME --addon-name aws-efs-csi-driver"
if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

echo ""
echo "Done."
