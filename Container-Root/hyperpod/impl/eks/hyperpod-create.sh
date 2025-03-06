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

# Create HyperPod cluster
echo "Creating HyperPod cluster ..." 
CMD="aws sagemaker create-cluster --cli-input-json file://hyperpod-config.json --region $AWS_REGION ${ENDPOINT_ARG}"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"
if [ "$?" == "0" ]; then
	echo ""
	echo "To monitor cluster status use:"
	echo "watch ./hyperpod-status.sh"
	echo ""
fi
popd

