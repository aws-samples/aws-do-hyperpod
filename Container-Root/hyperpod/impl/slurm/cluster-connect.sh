#!/bin/bash
# Open an SSM session to a node of a HyperPod Slurm cluster.
# Usage: cluster-connect.sh <cluster_name> [instance_group] [instance_id]
#   instance_group - defaults to the controller group (CONTROLLER_GROUP_NAME)
#   instance_id    - defaults to the first running node of the group
usage(){
	echo ""
	echo "Usage: $0 <cluster_name> [instance_group] [instance_id]"
	echo ""
}
if [ "$1" == "" ]; then
	usage
	exit 1
fi
CLUSTER_NAME=$1
GROUP=${2:-${CONTROLLER_GROUP_NAME:-controller}}
INSTANCE_ID=$3
REGION_OPT=""
if [ ! "${AWS_REGION}" == "" ]; then
	REGION_OPT="--region ${AWS_REGION}"
fi

# The cluster id is the last part of the cluster ARN
CMD="aws sagemaker describe-cluster --cluster-name ${CLUSTER_NAME} --query ClusterArn --output text ${REGION_OPT} ${ENDPOINT_ARG}"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
CLUSTER_ARN=$(eval "$CMD")
CLUSTER_ID=${CLUSTER_ARN##*/}
if [ "${CLUSTER_ID}" == "" ] || [ "${CLUSTER_ID}" == "None" ]; then
	echo "[ERROR] could not find cluster ${CLUSTER_NAME}"
	exit 1
fi

# Pick the first running node of the group unless an instance id was given
if [ "${INSTANCE_ID}" == "" ]; then
	CMD="aws sagemaker list-cluster-nodes --cluster-name ${CLUSTER_NAME} --query \"ClusterNodeSummaries[?InstanceGroupName=='${GROUP}' && InstanceStatus.Status=='Running'].InstanceId | [0]\" --output text ${REGION_OPT} ${ENDPOINT_ARG}"
	if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
	INSTANCE_ID=$(eval "$CMD")
fi
if [ "${INSTANCE_ID}" == "" ] || [ "${INSTANCE_ID}" == "None" ]; then
	echo "[ERROR] no running node found in instance group ${GROUP} of cluster ${CLUSTER_NAME}"
	exit 1
fi

TARGET="sagemaker-cluster:${CLUSTER_ID}_${GROUP}-${INSTANCE_ID}"
CMD="aws ssm start-session --target ${TARGET} ${REGION_OPT}"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"
