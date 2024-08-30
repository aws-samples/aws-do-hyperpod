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
aws sagemaker update-cluster \
    --cli-input-json file://hyperpod-update-config.json \
    --region $AWS_REGION
popd

