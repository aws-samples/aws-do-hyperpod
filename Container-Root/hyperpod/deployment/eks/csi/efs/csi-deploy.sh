#!/bin/bash

# Reference: https://www.eksworkshop.com/docs/fundamentals/storage/efs/efs-csi-driver

# Get cluster name from current context
export CLUSTER_NAME=$(kubectl config current-context | cut -d '/' -f 2)

# Get cluster OIDC provider
export CLUSTER_OIDC=$(aws eks describe-cluster --name $CLUSTER_NAME --query "cluster.identity.oidc.issuer" --output text)
export CLUSTER_OIDC_ID=$(echo $CLUSTER_OIDC | cut -d '/' -f 5)

# Associate OIDC provider if needed
OIDC_PROVIDER=$(aws iam list-open-id-connect-providers | grep $CLUSTER_OIDC_ID)
echo ""
if [ "${OIDC_PROVIDER}" == "" ]; then
	echo "Associating EKS OIDC Provider $CLUSTER_OIDC_ID ..."
	eksctl utils associate-iam-oidc-provider --cluster $CLUSTER_NAME --approve
else
	echo "EKS OIDC Provider $CLUSTER_OIDC_ID association found"
fi

# Get cluster region and account id
export CLUSTER_ARN=$(aws eks describe-cluster --name $CLUSTER_NAME --query "cluster.arn" --output text)
export CLUSTER_REGION=$(echo $CLUSTER_ARN | cut -d ':' -f 4)
export CLUSTER_ACCOUNT=$(echo $CLUSTER_ARN | cut -d ':' -f 5)

# Create trust policy document
cat ./aws-efs-csi-driver-trust-policy.json-template | envsubst > ./aws-efs-csi-driver-trust-policy-${CLUSTER_NAME}.json
# Create clusster-specific CSI driver role, if it does not exist
export EFS_CSI_ROLE_NAME=AmazonEKS_EFS_CSI_DriverRole-${CLUSTER_NAME}
export EFS_CSI_ROLE_ARN=$(aws iam get-role --role-name $EFS_CSI_ROLE_NAME --query Role.Arn --output text)
echo ""
if [ "$EFS_CSI_ROLE_ARN" == "" ]; then
	echo "Creating role $EFS_CSI_ROLE_NAME ..."
	aws iam create-role --role-name $EFS_CSI_ROLE_NAME --assume-role-policy-document file://aws-efs-csi-driver-trust-policy-${CLUSTER_NAME}.json
	aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy --role-name $EFS_CSI_ROLE_NAME
	export EFS_CSI_ROLE_ARN=$(aws iam get-role --role-name $EFS_CSI_ROLE_NAME --query Role.Arn --output text)
else
	echo "Role $EFS_CSI_ROLE_NAME found."
fi

echo ""
echo "Deploying aws-efs-csi-driver addon to $CLUSTER_NAME ..."

CMD="aws eks create-addon --cluster-name $CLUSTER_NAME --addon-name aws-efs-csi-driver --service-account-role-arn $EFS_CSI_ROLE_ARN"
if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

CMD="aws eks wait addon-active --cluster-name $CLUSTER_NAME --addon-name aws-efs-csi-driver"
if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

echo "Done."
