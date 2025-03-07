#!/bin/bash

# Get cluster name and other info from current context
CLUSTER_NAME=$(kubectl config current-context | cut -d '/' -f 2)
VPC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --query "cluster.resourcesVpcConfig.vpcId" --output text)
CIDR_BLOCK=$(aws ec2 describe-vpcs --vpc-ids $VPC_ID --query "Vpcs[].CidrBlock" --output text)

echo ""
echo "Cluster name: $CLUSTER_NAME"
echo "VPC ID: $VPC_ID"
echo "CIDR_BLOCK: $CIDR_BLOCK"

echo ""
HYPERPOD_SECURITY_GROUP_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --query cluster.resourcesVpcConfig.securityGroupIds[0] --output text)
echo "HYPERPOD_SECURITY_GROUP_ID=$HYPERPOD_SECURITY_GROUP_ID"

if [ "$HYPERPOD_SECURITY_GROUP_ID" == "" ]; then
	echo ""
	MOUNT_TARGET_GROUP_NAME="${CLUSTER_NAME}-efs"
	echo "Checking security group ... $MOUNT_TARGET_GROUP_NAME"
	MOUNT_TARGET_GROUP_ID=$(aws ec2 describe-security-groups --filter Name=vpc-id,Values=$VPC_ID Name=group-name,Values=${MOUNT_TARGET_GROUP_NAME} --query 'SecurityGroups[*].[GroupId]' --output text)


	if [ "$MOUNT_TARGET_GROUP_ID" == "" ]; then
		echo ""
		echo "Creating security group ..."
		MOUNT_TARGET_GROUP_DESC="Access to EFS from EKS worker nodes"
		aws ec2 create-security-group --group-name $MOUNT_TARGET_GROUP_NAME --description "$MOUNT_TARGET_GROUP_DESC" --vpc-id $VPC_ID
		sleep 5
		MOUNT_TARGET_GROUP_ID=$(aws ec2 describe-security-groups --filter Name=vpc-id,Values=$VPC_ID Name=group-name,Values=${MOUNT_TARGET_GROUP_NAME} --query 'SecurityGroups[*].[GroupId]' --output text)
		# open EFS port
		aws ec2 authorize-security-group-ingress --group-id $MOUNT_TARGET_GROUP_ID --protocol tcp --port 2049 --cidr $CIDR_BLOCK
		sleep 2
	else
		echo "Exists"
	fi
else
	MOUNT_TARGET_GROUP_ID=$HYPERPOD_SECURITY_GROUP_ID
fi

echo ""
echo "Creating EFS volume ..."
FILE_SYSTEM_ID=$(aws efs create-file-system --tags Key=owner,Value="$CLUSTER_NAME" | jq --raw-output '.FileSystemId')
echo $FILE_SYSTEM_ID
sleep 10

echo ""
echo "Creating mount targets ..."
SUBNETS=$(aws ec2 describe-subnets --filter Name=vpc-id,Values=$VPC_ID Name=map-public-ip-on-launch,Values=true --query 'Subnets[*].SubnetId' --output text)
for subnet in ${SUBNETS}
do
    echo "Creating mount target in" $subnet "in security group" $MOUNT_TARGET_GROUP_ID "for efs" $FILE_SYSTEM_ID
    aws efs create-mount-target --file-system-id $FILE_SYSTEM_ID --subnet-id $subnet --security-groups $MOUNT_TARGET_GROUP_ID
    sleep 2
done


STATE=$(aws efs describe-mount-targets --file-system-id $FILE_SYSTEM_ID | jq --raw-output '.MountTargets[].LifeCycleState' | xargs | cut -d ' ' -f 1)
echo "Mount target state ... $STATE"
while [ ! "$STATE" == "available" ]; do
	sleep 10
	STATE=$(aws efs describe-mount-targets --file-system-id $FILE_SYSTEM_ID | jq --raw-output '.MountTargets[].LifeCycleState' | xargs | cut -d ' ' -f 1)
	echo "Mount target state ... $STATE"
done
echo "Done ..."

echo ""
echo "FILE_SYSTEM_ID"
echo "${FILE_SYSTEM_ID}"

