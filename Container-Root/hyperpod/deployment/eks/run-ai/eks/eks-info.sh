#!/bin/bash

export CLUSTER_NAME=eks-runai

export CLUSTER_DESCRIPTION=$(aws eks describe-cluster --name ${CLUSTER_NAME})

export VPC_ID=$(echo $CLUSTER_DESCRIPTION | jq -r .cluster.resourcesVpcConfig.vpcId)

export SECURITY_GROUP_ID=$(echo $CLUSTER_DESCRIPTION | jq -r .cluster.resourcesVpcConfig.clusterSecurityGroupId)

export PRIVATE_SUBNET_ID=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=${VPC_ID} Name=map-public-ip-on-launch,Values=false --query "Subnets[0].SubnetId" --output text)

export NAT_GATEWAY_ID=$(aws ec2 describe-nat-gateways --query "NatGateways[?VpcId=='$VPC_ID'].NatGatewayId" --output text)

echo ""
echo "CLUSTER_NAME=${CLUSTER_NAME}"
echo "VPC_ID=${VPC_ID}"
echo "SECURITY_GROUP_ID=${SECURITY_GROUP_ID}"
echo "PRIVATE_SUBNET_ID=${PRIVATE_SUBNET_ID}"
echo "NAT_GATEWAY_ID=${NAT_GATEWAY_ID}"
echo ""

