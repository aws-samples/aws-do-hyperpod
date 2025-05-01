#!/bin/bash

source .env

echo ""
echo "Setting up FSx for Lustre CSI ..."

echo ""
echo "Associating IAM OIDC identity provider ..."
CMD="eksctl utils associate-iam-oidc-provider --cluster $EKS_CLUSTER_NAME --approve"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "${CMD}"

echo ""
echo "Deploying FSxL CSI driver using helm ..."
CMD="helm repo add aws-fsx-csi-driver https://kubernetes-sigs.github.io/aws-fsx-csi-driver"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "${CMD}"
CMD="helm repo update"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "${CMD}"
CMD="helm upgrade --install aws-fsx-csi-driver aws-fsx-csi-driver/aws-fsx-csi-driver\
  --namespace kube-system"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "${CMD}"

echo ""
echo "Creating IAM service account fsx-csi-controller-sa..."
CMD="eksctl create iamserviceaccount --name fsx-csi-controller-sa --override-existing-serviceaccounts --namespace kube-system --cluster $EKS_CLUSTER_NAME --attach-policy-arn arn:aws:iam::aws:policy/AmazonFSxFullAccess --approve --role-name FSXCSI-${EKS_CLUSTER_NAME} --region $AWS_REGION"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "${CMD}"

echo ""
echo "Annotating service account with IAM role ARN ..."
SA_ROLE_ARN=$(aws iam get-role --role-name FSXCSI-${EKS_CLUSTER_NAME} --query 'Role.Arn' --output text)
CMD="kubectl annotate serviceaccount -n kube-system fsx-csi-controller-sa  eks.amazonaws.com/role-arn=${SA_ROLE_ARN} --overwrite=true"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "${CMD}"

echo ""
echo "Restarting the fsx-csi-controller ..."
CMD="kubectl rollout restart deployment fsx-csi-controller -n kube-system"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "${CMD}"

if [ ! "$SUBNET_ID" == "" ]; then
	echo ""
	echo "Creating storage class ..."

cat <<EOF> storageclass.yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: fsx-sc
provisioner: fsx.csi.aws.com
parameters:
  subnetId: $SUBNET_ID
  securityGroupIds: $SECURITY_GROUP_ID
  deploymentType: PERSISTENT_2
  automaticBackupRetentionDays: "0"
  copyTagsToBackups: "true"
  perUnitStorageThroughput: "250"
  dataCompressionType: "LZ4"
  fileSystemTypeVersion: "2.15"
mountOptions:
  - flock
EOF

	CMD="kubectl apply -f ./storageclass.yaml"
	if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
	eval "${CMD}"

else
	echo "SUBNET_ID and SECURITY_GROUP_ID are required."
	echo "Storage class not created"
fi

