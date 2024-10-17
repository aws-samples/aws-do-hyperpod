#!/bin/bash

# Ref: https://catalog.us-east-1.prod.workshops.aws/workshops/2433d39e-ccfe-4c00-9d3d-9917b729258e/en-US/09-tips/01-ssm-login

usage(){
	echo ""
	echo "Usage: $0 <node_name>"
	echo ""
	echo "node_name  - full or partial cluster node name to open ssm session into"
	echo ""
}

if [ "$1" == "" ]; then
	usage
else

	# Get instance id
	node_id="$1"
	node_line=$(kubectl get nodes -L node.kubernetes.io/instance-type -L sagemaker.amazonaws.com/node-health-status -L sagemaker.amazonaws.com/deep-health-check-status | grep $node_id | head -n 1)
	node_name=$(echo $node_line | cut -d ' ' -f 1)
	node_type=$(echo $node_line | cut -d ' ' -f 6)
	instance_uid=$(echo $node_name | cut -d '-' -f 3)
	instance_id=$(echo i-${instance_uid})

	# Get cluster id and instance group name
	pushd /hyperpod
	desc=$(./hyperpod-describe.sh | tail -n +5)
	cluster_id=$(echo $desc | jq -r .ClusterArn | cut -d '/' -f 2)
	popd
	instance_group_name=$(echo $desc | jq -r ".InstanceGroups[] | select(.InstanceType==\"$node_type\") | .InstanceGroupName")
	
	echo ""
	echo "Instance ID: $instance_id"
	echo "Cluster ID: $cluster_id"
	echo "Instance Group Name: $instance_group_name"
	echo ""

	# Construct and execute SSM command
	CMD="aws ssm start-session --target sagemaker-cluster:${cluster_id}_${instance_group_name}-${instance_id} --region $REGION"
	if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
	eval "$CMD"

fi
