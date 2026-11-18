#!/bin/bash
# Delete a HyperPod Slurm cluster.
# By default only the HyperPod cluster is deleted. When DELETE_ALL=true
# (conf/env.conf), the CloudFormation stacks are deleted as well, in reverse
# order of creation: FSx stack first, then the base stack.
# Settings come from conf/env.conf and ${CONF}/env_input, sourced by the caller.

POLL_INTERVAL=${POLL_INTERVAL:-30}
POLL_MAX=${POLL_MAX:-120}

if [ ! "$1" == "" ]; then HYPERPOD_NAME=$1; fi

REGION_OPT=""
if [ ! "${AWS_REGION}" == "" ]; then
	REGION_OPT="--region ${AWS_REGION}"
fi

# run <command> - show the command when VERBOSE is not false, then run it
run() {
	if [ ! "$VERBOSE" == "false" ]; then echo -e "\n$1\n"; fi
	eval "$1"
}

# cluster_exists - true if the HyperPod cluster exists
cluster_exists() {
	aws sagemaker describe-cluster --cluster-name ${HYPERPOD_NAME} ${REGION_OPT} ${ENDPOINT_ARG} > /dev/null 2>&1
}

# stack_status <stack-name> - prints the stack status, nothing if it does not exist
stack_status() {
	aws cloudformation describe-stacks --stack-name "$1" ${REGION_OPT} \
		--query 'Stacks[0].StackStatus' --output text 2>/dev/null
}

# delete_stack <stack-name> - delete a stack and wait. Returns 1 on failure.
delete_stack() {
	local stack=$1 status
	status=$(stack_status "${stack}")
	if [ -z "${status}" ]; then
		echo "CloudFormation stack ${stack} does not exist"
		return 0
	fi
	echo ""
	echo "Deleting CloudFormation stack: ${stack}"
	run "aws cloudformation delete-stack --stack-name ${stack} ${REGION_OPT}"
	echo "Waiting for stack deletion to complete ..."
	run "aws cloudformation wait stack-delete-complete --stack-name ${stack} ${REGION_OPT}"
	status=$(stack_status "${stack}")
	if [ -n "${status}" ]; then
		echo "[ERROR] CloudFormation stack ${stack} is in state ${status}"
		return 1
	fi
	echo "CloudFormation stack ${stack} deleted"
}

echo ""
echo "Deleting HyperPod cluster: ${HYPERPOD_NAME}"
if [ "$DELETE_ALL" == "true" ]; then
	echo "Also deleting CloudFormation stacks: ${FSX_STACK_ID} (if CREATE_FSX=true), ${STACK_ID}"
fi
echo ""
read -r -p "Are you sure? [y/N] " response
case "$response" in
	[yY][eE][sS]|[yY])
		;;
	*)
		echo ""
		echo "Cluster deletion cancelled"
		echo ""
		exit 0
		;;
esac

# Delete the HyperPod cluster
if cluster_exists; then
	run "aws sagemaker delete-cluster --cluster-name ${HYPERPOD_NAME} ${REGION_OPT} ${ENDPOINT_ARG}"
	if [ "$?" != "0" ]; then
		echo "[ERROR] failed to delete HyperPod cluster ${HYPERPOD_NAME}"
		exit 1
	fi
else
	echo "HyperPod cluster ${HYPERPOD_NAME} does not exist"
fi

if [ "$DELETE_ALL" == "true" ]; then
	# The stacks cannot be deleted while the cluster nodes still use their network
	echo ""
	echo "Waiting for HyperPod cluster deletion to complete ..."
	count=0
	while cluster_exists; do
		count=$((count + 1))
		if [ "$count" -gt "${POLL_MAX}" ]; then
			echo "[ERROR] timed out waiting for cluster ${HYPERPOD_NAME} to be deleted"
			exit 1
		fi
		echo "Cluster ${HYPERPOD_NAME} still exists, checking again in ${POLL_INTERVAL} sec ..."
		sleep ${POLL_INTERVAL}
	done
	echo "HyperPod cluster ${HYPERPOD_NAME} deleted"

	if [ "$CREATE_FSX" == "true" ]; then
		delete_stack ${FSX_STACK_ID} || exit 1
	fi
	delete_stack ${STACK_ID} || exit 1
fi
