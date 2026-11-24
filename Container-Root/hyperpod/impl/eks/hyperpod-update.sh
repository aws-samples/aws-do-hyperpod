#!/bin/bash

if [ "$EKS_CLUSTER_NAME" == "" ]; then
	export EKS_CLUSTER_NAME=aws-do-hyperpod-eks
fi

if [ "$HYPERPOD_NAME" == "" ]; then
	export HYPERPOD_NAME=$EKS_CLUSTER_NAME
fi

if [ "$STACK_ID" == "" ]; then
	export STACK_ID="cfn-${EKS_CLUSTER_NAME}"
fi

if [ "$RESOURCE_NAME_PREFIX" == "" ]; then
	export RESOURCE_NAME_PREFIX=aws-do-hyperpod
fi

pushd ${ENV_HOME}impl/eks/src

# Extract output environment variables
scripts/create_config.sh
source ./env_vars

# Update HyperPod config 
mv env_vars ${ENV_HOME}${CONF}
pushd ${ENV_HOME}${CONF}
./generate-update-config.sh
cat ./hyperpod-update-config.json

# Update HyperPod cluster
CMD="aws sagemaker update-cluster --cli-input-json file://hyperpod-update-config.json --region $AWS_REGION ${ENDPOINT_ARG}"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "${CMD}"
UPDATE_RC=$?
popd

# Enable autoscaling after the cluster is updated (optional)
if [ "$UPDATE_RC" == "0" ] && [ "$ENABLE_AUTOSCALING" == "true" ]; then
	# update-cluster returns before the new instance group exists, so wait for it
	POLL_INTERVAL=${POLL_INTERVAL:-30}
	POLL_MAX=${POLL_MAX:-120}
	echo "Waiting for instance group ${AUTOSCALE_GROUP_NAME} to be InService ..."
	count=0
	while true; do
		GROUP_STATUS=$(aws sagemaker describe-cluster --cluster-name ${HYPERPOD_NAME} --query "InstanceGroups[?InstanceGroupName=='${AUTOSCALE_GROUP_NAME}'].Status | [0]" --output text --region $AWS_REGION ${ENDPOINT_ARG} 2>/dev/null)
		if [ "${GROUP_STATUS}" == "InService" ]; then break; fi
		if [ "${GROUP_STATUS}" == "Failed" ]; then
			echo "[ERROR] instance group ${AUTOSCALE_GROUP_NAME} failed"
			exit 1
		fi
		count=$((count + 1))
		if [ "$count" -gt "${POLL_MAX}" ]; then
			echo "[ERROR] timed out waiting for instance group ${AUTOSCALE_GROUP_NAME}, last status '${GROUP_STATUS}'"
			exit 1
		fi
		echo "Instance group status is '${GROUP_STATUS}', checking again in ${POLL_INTERVAL} sec ..."
		sleep ${POLL_INTERVAL}
	done
	echo "Enabling autoscaling ..."
	${ENV_HOME}impl/eks/hyperpod-autoscaling-enable.sh
fi

