#!/bin/bash

set -e

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

if [ "$CREATE_EKS_CLUSTER" == "" ]; then
	export CREATE_EKS_CLUSTER=true
fi

export REGION_OPT=""
if [ ! "${AWS_REGION}" == "" ]; then
	export REGION_OPT="--region ${AWS_REGION}"
fi

pushd ${ENV_HOME}impl/eks/src

# Create cfn stack if it does not exist
CMD="aws cloudformation list-stacks --query 'StackSummaries[?StackStatus==\`CREATE_COMPLETE\`].StackName' ${REGION_OPT} | grep \\\"${STACK_ID}\\\" | wc -l | tr -d ' '"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
STACK_COUNT=$(eval $CMD)
echo "STACK_COUNT=$STACK_COUNT"
if [ "$STACK_COUNT" == "0" ]; then

	# Create parameter file ${ENV_HOME}${CONF}/parameters.json
	cat cfn/parameters.json-template | envsubst > ${ENV_HOME}${CONF}/parameters.json

	# Create stack
	echo "Creating CloudFormation stack ${STACK_ID} ..."
	/util/cfn-create.sh ${STACK_ID} cfn/hyperpod-eks-full-stack.yaml file://${ENV_HOME}${CONF}/parameters.json

	# Connect to EKS cluster
        echo "Connecting to EKS cluster ..."
	aws eks update-kubeconfig --name $EKS_CLUSTER_NAME
	kubectl config current-context 
	kubectl get svc
else
	echo "CloudFormation stack ${STACK_ID} already exists"
fi

echo "Detecting dependencies ..."
DEPENDENCIES_CNT=$(helm list --namespace kube-system | grep dependencies | wc -l)
if [ ! "$DEPENDENCIES_CNT" == 0 ]; then
	echo "Old dependencies detected ... uninstaling ..."
	CMD="helm uninstall dependencies --namespace kube-system"
	if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
	eval "$CMD"
	echo "Sleeping for 5 sec to allow uninstall to complete ..."
	sleep 5
fi

echo "Installing helm chart ..."
pushd sagemaker-hyperpod-cli/helm_chart
./install_dependencies.sh
helm lint ./HyperPodHelmChart
helm dependencies update ./HyperPodHelmChart
CMD="helm install dependencies ./HyperPodHelmChart --namespace kube-system"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"
popd

# Extract output environment variables
source ${ENV_HOME}${CONF}/env_input
scripts/create_config.sh
source ./env_vars

# Upload lifecycle scripts
aws s3 cp lifecyclescripts/on_create.sh s3://$S3_BUCKET_NAME

# Create HyperPod config 
echo "Generating HyperPod config ..."
mv env_vars ${ENV_HOME}${CONF}
pushd ${ENV_HOME}${CONF}
./generate-config.sh
cat ./hyperpod-config.json

# Prepare IAM for autoscaling (optional). It must be in place before the cluster is created.
if [ "$ENABLE_AUTOSCALING" == "true" ]; then
	echo "Autoscaling is enabled, preparing IAM ..."
	${ENV_HOME}impl/eks/hyperpod-autoscaling-iam.sh
fi
# Create HyperPod cluster
echo "Creating HyperPod cluster ..." 
CMD="aws sagemaker create-cluster --cli-input-json file://hyperpod-config.json --region $AWS_REGION ${ENDPOINT_ARG}"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
if [ "$ENABLE_AUTOSCALING" == "true" ]; then
	# IAM changes can take a while to become visible to HyperPod. Retry while the
	# error says the role does not have sufficient permissions.
	RETRY_INTERVAL=${RETRY_INTERVAL:-15}
	RETRY_MAX=${RETRY_MAX:-12}
	attempt=0
	while true; do
		set +e
		CREATE_OUT=$(eval "$CMD" 2>&1)
		CREATE_RC=$?
		set -e
		echo "${CREATE_OUT}"
		if [ "$CREATE_RC" == "0" ]; then break; fi
		attempt=$((attempt + 1))
		if echo "${CREATE_OUT}" | grep -q "does not have sufficient permissions" && [ "$attempt" -le "${RETRY_MAX}" ]; then
			echo "The role changes are not visible to HyperPod yet, retrying in ${RETRY_INTERVAL} sec (attempt ${attempt} of ${RETRY_MAX}) ..."
			sleep ${RETRY_INTERVAL}
			continue
		fi
		echo "[ERROR] failed to create HyperPod cluster ${HYPERPOD_NAME}"
		exit $CREATE_RC
	done
else
	eval "$CMD"
fi
echo ""
echo "To monitor cluster status use:"
echo "watch ./hyperpod-status.sh"
echo ""
if [ "$ENABLE_AUTOSCALING" == "true" ]; then
	echo "Autoscaling is enabled. The cluster starts with 0 instances in worker-group-1 and worker-group-2."
	echo "When the cluster and autoscaling are InService, create the HyperpodNodeClass and NodePool"
	echo "for the instance groups you want to scale, for example:"
	echo "kubectl apply -f ${ENV_HOME}impl/eks/src/manifests/autoscaling/"
	echo ""
fi
popd
