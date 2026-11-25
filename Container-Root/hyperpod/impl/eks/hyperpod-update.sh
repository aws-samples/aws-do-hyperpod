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
# Enable autoscaling on update (optional), unless the cluster already has it
export AUTOSCALING_ENABLE_ON_UPDATE=false
if [ "$ENABLE_AUTOSCALING" == "true" ]; then
	AUTOSCALING_MODE=$(aws sagemaker describe-cluster --cluster-name ${HYPERPOD_NAME} --query "AutoScaling.Mode" --output text --region $AWS_REGION ${ENDPOINT_ARG} 2>/dev/null)
	if [ "$AUTOSCALING_MODE" == "Enable" ]; then
		echo "Autoscaling is already enabled on cluster ${HYPERPOD_NAME}"
	else
		echo "Autoscaling will be enabled on cluster ${HYPERPOD_NAME}, preparing IAM ..."
		${ENV_HOME}impl/eks/hyperpod-autoscaling-iam.sh || exit 1
		export AUTOSCALING_ENABLE_ON_UPDATE=true
	fi
fi

# Update HyperPod config 
mv env_vars ${ENV_HOME}${CONF}
pushd ${ENV_HOME}${CONF}
./generate-update-config.sh
cat ./hyperpod-update-config.json

# Update HyperPod cluster
CMD="aws sagemaker update-cluster --cli-input-json file://hyperpod-update-config.json --region $AWS_REGION ${ENDPOINT_ARG}"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
if [ "$AUTOSCALING_ENABLE_ON_UPDATE" == "true" ]; then
	# IAM changes can take a while to become visible to HyperPod. Retry while the
	# error says the role does not have sufficient permissions.
	RETRY_INTERVAL=${RETRY_INTERVAL:-15}
	RETRY_MAX=${RETRY_MAX:-12}
	attempt=0
	while true; do
		UPDATE_OUT=$(eval "${CMD}" 2>&1)
		UPDATE_RC=$?
		echo "${UPDATE_OUT}"
		if [ "$UPDATE_RC" == "0" ]; then break; fi
		attempt=$((attempt + 1))
		if echo "${UPDATE_OUT}" | grep -q "does not have sufficient permissions" && [ "$attempt" -le "${RETRY_MAX}" ]; then
			echo "The role changes are not visible to HyperPod yet, retrying in ${RETRY_INTERVAL} sec (attempt ${attempt} of ${RETRY_MAX}) ..."
			sleep ${RETRY_INTERVAL}
			continue
		fi
		echo "[ERROR] failed to update HyperPod cluster ${HYPERPOD_NAME}"
		exit $UPDATE_RC
	done
	# Wait for autoscaling to be InService
	POLL_INTERVAL=${POLL_INTERVAL:-30}
	POLL_MAX=${POLL_MAX:-120}
	echo "Waiting for autoscaling to be InService ..."
	count=0
	while true; do
		AUTOSCALING_STATUS=$(aws sagemaker describe-cluster --cluster-name ${HYPERPOD_NAME} --query "AutoScaling.Status" --output text --region $AWS_REGION ${ENDPOINT_ARG} 2>/dev/null)
		if [ "$AUTOSCALING_STATUS" == "InService" ]; then break; fi
		if [ "$AUTOSCALING_STATUS" == "Failed" ]; then
			echo "[ERROR] autoscaling failed: $(aws sagemaker describe-cluster --cluster-name ${HYPERPOD_NAME} --query "AutoScaling.FailureMessage" --output text --region $AWS_REGION ${ENDPOINT_ARG} 2>/dev/null)"
			exit 1
		fi
		count=$((count + 1))
		if [ "$count" -gt "${POLL_MAX}" ]; then
			echo "[ERROR] timed out waiting for autoscaling, last status '${AUTOSCALING_STATUS}'"
			exit 1
		fi
		echo "Autoscaling status is '${AUTOSCALING_STATUS}', checking again in ${POLL_INTERVAL} sec ..."
		sleep ${POLL_INTERVAL}
	done
	echo ""
	echo "Autoscaling is enabled on cluster ${HYPERPOD_NAME}."
	echo "Create the HyperpodNodeClass and NodePool for the instance groups you want to scale, for example:"
	echo "kubectl apply -f ${ENV_HOME}impl/eks/src/manifests/autoscaling/"
	echo ""
else
	eval "${CMD}"
fi
popd
