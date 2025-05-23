#!/bin/bash

echo ""
echo "Creating service account ..."

# Set paramenters
export CLUSTER_NAME=$(kubectl config current-context | cut -d '/' -f 2)
export account=$(aws sts get-caller-identity | jq -r '.Account')
export CLUSTER_INFO=$(eksctl get cluster $CLUSTER_NAME --output json)
export VPC_ID=$(echo $CLUSTER_INFO | jq -r .[].ResourcesVpcConfig.VpcId)
export AWS_REGION=$(aws configure get region)

# Associate OIDC provider
echo ""
echo "Associating OIDC provider ..."
eksctl utils associate-iam-oidc-provider \
    --region ${AWS_REGION} \
    --cluster ${CLUSTER_NAME} \
    --approve

# Create policy if it does not already exist
echo ""
echo "Setting up IAM policy ..."
export IAM_POLICY=$(aws iam get-policy --policy-arn arn:aws:iam::${account}:policy/AWSLoadBalancerControllerIAMPolicy)
if [ "$IAM_POLICY" == "" ]; then
	echo "Creating AWS Load Balancer Controller IAM Policy ..."
	json_out=$(aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://alb-controller-policy.json)
	POLICY_ARN=$(echo $json_out | jq -r '.Policy.Arn')
	echo "POLICY_ARN=$POLICY_ARN"
else
	echo "IAM policy AWSLoadBalancerControllerIAMPolicy already exists"
	POLICY_ARN=$(echo $IAM_POLICY | jq -r .Policy.Arn)
fi

# Create IAM service account if it does not exist
echo ""
echo "Setting up service account ..."
export ROLE_NAME=AmazonEKSLoadBalancerControllerRole
#ROLE=$(aws iam get-role --role-name=${ROLE_NAME})
IAM_SA_NAME=alb-controller-${CLUSTER_NAME}
ACCOUNT_EXISTS=$(eksctl get iamserviceaccount --cluster $CLUSTER_NAME | grep ${IAM_SA_NAME} | wc -l)
if [ "$ACCOUNT_EXISTS" == "0" ]; then
        echo "Creating IAM Service Account ${IAM_SA_NAME} ..."

        eksctl create iamserviceaccount \
        --cluster=${CLUSTER_NAME} \
        --namespace=kube-system \
        --name=${IAM_SA_NAME} \
        --role-name ${ROLE_NAME} \
        --attach-policy-arn=${POLICY_ARN} \
	--override-existing-serviceaccounts \
       	--approve
else
        echo "IAM Service Account $IAM_SA_NAME already exists"
fi

# Install helm chart
echo ""
echo "Installing helm chart ..."
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=${CLUSTER_NAME} \
  --set serviceAccount.create=false \
  --set serviceAccount.name=${IAM_SA_NAME} \
  --set vpcId=${VPC_ID} \
  --set region=${AWS_REGION}

# Verify installation
echo ""
echo "Verifying installation ..."
kubectl get deployment -n kube-system aws-load-balancer-controller
echo ""
kubectl get pods -n kube-system | grep aws-load-balancer
echo ""

# Tag public subnets
echo ""
echo "Tagging public subnets ..."
PUBLIC_SUBNETS=$(aws ec2 describe-subnets --filters "[ {\"Name\":\"vpc-id\",\"Values\":[\"${VPC_ID}\"]}, {\"Name\":\"map-public-ip-on-launch\",\"Values\":[\"true\"]} ]" --query 'Subnets[*].{SubnetId:SubnetId}' --output text)
for SUBNET_ID in $PUBLIC_SUBNETS; do
    echo "Subnet $SUBNET_ID ..."
    aws ec2 create-tags --resources $SUBNET_ID --tags Key=kubernetes.io/role/elb,Value=1
done

# Verify tags
echo ""
echo "Verifying public subnet tags ..."
for SUBNET_ID in $PUBLIC_SUBNETS; do
    echo ""
    echo "Subnet $SUBNET_ID ..."
    aws ec2 describe-tags --filters "Name=resource-id,Values=${SUBNET_ID}"
done

echo ""
