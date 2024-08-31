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

pushd ${ENV_HOME}impl/eks/src

# Update cfn template
#PRINCIPAL_ARN=$(aws sts get-caller-identity --query Arn --output text)
#sed -i "s%\!ImportValue WorkshopRoleArn%\'${PRINCIPAL_ARN}\'%g" cfn/hyperpod-eks-full-stack.yaml
#sed -i "s%'HyperPodServiceRoleAlternative'%\!Sub \'\${ResourceNamePrefix}-HyperPodServiceRoleAlternative\'%g" cfn/hyperpod-eks-full-stack.yaml
#/util/p-rm.sh UserAccessEntry cfn/hyperpod-eks-full-stack.yaml

# Create cfn stack if it does not exist
CMD="aws cloudformation list-stacks --query 'StackSummaries[?StackStatus==\`CREATE_COMPLETE\`].StackName' | grep \\\"${STACK_ID}\\\" | wc -l | tr -d ' '"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
STACK_COUNT=$(eval $CMD)
echo "STACK_COUNT=$STACK_COUNT"
if [ "$STACK_COUNT" == "0" ]; then
        
	# Create stack
	echo "Creating CloudFormation stack ${STACK_ID} ..."
	/util/cfn-create.sh ${STACK_ID} cfn/hyperpod-eks-full-stack.yaml ParameterKey=ResourceNamePrefix,ParameterValue=$RESOURCE_NAME_PREFIX ParameterKey=CreateEKSCluster,ParameterValue=$CREATE_EKS_CLUSTER ParameterKey=AvailabilityZoneId,ParameterValue=$AVAILABILITY_ZONE_ID ParameterKey=VpcCIDR,ParameterValue=$VPC_CIDR ParameterKey=PublicSubnet1CIDR,ParameterValue=$PUBLIC_SUBNET1_CIDR ParameterKey=PublicSubnet2CIDR,ParameterValue=$PUBLIC_SUBNET2_CIDR ParameterKey=PublicSubnet3CIDR,ParameterValue=$PUBLIC_SUBNET3_CIDR ParameterKey=PrivateSubnet1CIDR,ParameterValue=$PRIVATE_SUBNET1_CIDR ParameterKey=KubernetesVersion,ParameterValue=$KUBERNETES_VERSION ParameterKey=EKSPrivateSubnet1CIDR,ParameterValue=$EKS_PRIVATE_SUBNET1_CIDR ParameterKey=EKSPrivateSubnet2CIDR,ParameterValue=$EKS_PRIVATE_SUBNET2_CIDR ParameterKey=EKSPrivateSubnet3CIDR,ParameterValue=$EKS_PRIVATE_SUBNET3_CIDR

	# Connect to EKS cluster
        echo "Connecting to EKS cluster ..."
	aws eks update-kubeconfig --name $EKS_CLUSTER_NAME
	kubectl config current-context 
	kubectl get svc
else
	echo "CloudFormation stack ${STACK_ID} already exists"
fi

echo "Applying manifests ..."
# Apply HyperPod Manifests
NS_COUNT=$(kubectl get namespace hyperpod | grep hyperpod | wc -l)
if [ "$NS_COUNT" == "1" ]; then
	echo "Namespace hyperpod already exists"
else
	kubectl create namespace hyperpod
fi
kubectl apply -f manifests

# Extract output environment variables
source ${ENV_HOME}${CONF}/env_input
scripts/create_config.sh
source ./env_vars


# Upload lifecycle scripts
aws s3 cp lifecyclescripts/on_create.sh s3://$BUCKET_NAME

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
popd

