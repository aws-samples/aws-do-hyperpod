#!/bin/bash

help(){
	echo ""
	echo "Usage: $0 [--dry-run]"
        echo "       Labels all nodes in the cluster with a node-family label for easier selection"
	echo "       This adds labels in the format: node.hyperpod.aws/family=<instance-family>"
	echo "       For example: node.hyperpod.aws/family=g5, node.hyperpod.aws/family=p4d, etc."
	echo ""
	echo "       --dry-run - only show commands that would be executed without actually labeling nodes"
	echo ""
}

if [ "$1" == "--help" ]; then
	help
	exit 0
fi

DRY_RUN=false
if [ "$1" == "--dry-run" ]; then
	DRY_RUN=true
fi

echo ""
echo "Adding node-family labels to all cluster nodes..."
echo ""

# Get unique instance types in the cluster
INSTANCE_TYPES=$(kubectl get nodes -o jsonpath='{.items[*].metadata.labels.node\.kubernetes\.io/instance-type}' | tr ' ' '\n' | sort | uniq)

# Process each instance type
for INSTANCE_TYPE in $INSTANCE_TYPES; do
    # Extract the instance family (g5, p4d, etc.)
    INSTANCE_FAMILY=$(echo $INSTANCE_TYPE | sed -E 's/ml\.//g' | sed -E 's/([a-z]+[0-9]+).*/\1/g')
    
    echo "Processing instance type: $INSTANCE_TYPE -> family: $INSTANCE_FAMILY"
    
    # Get all nodes with this instance type
    NODES=$(kubectl get nodes -l node.kubernetes.io/instance-type=$INSTANCE_TYPE -o jsonpath='{.items[*].metadata.name}')
    
    # Label each node
    for NODE in $NODES; do
        CMD="kubectl label node $NODE node.hyperpod.aws/family=$INSTANCE_FAMILY --overwrite"
        echo "$CMD"
        
        if [ "${DRY_RUN}" != "true" ]; then
            eval "$CMD"
        fi
    done
done

echo ""
if [ "${DRY_RUN}" == "true" ]; then
    echo "Dry run completed. No labels were applied."
else
    echo "Node family labeling completed. You can now select nodes using:"
    echo "  kubectl get nodes -l node.hyperpod.aws/family=<family>"
    echo "For example:"
    echo "  kubectl get nodes -l node.hyperpod.aws/family=g5"
fi
echo ""
