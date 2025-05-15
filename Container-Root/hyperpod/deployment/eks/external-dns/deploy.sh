#!/bin/bash

# Set parameters
export CLUSTER_NAME=$(kubectl config current-context | cut -d '/' -f 2)
export account=$(aws sts get-caller-identity | jq -r '.Account')
export AWS_REGION=$(aws configure get region)

# Associate OIDC provider
echo ""
echo "Associating OIDC provider ..."
eksctl utils associate-iam-oidc-provider \
    --region ${AWS_REGION} \
    --cluster ${CLUSTER_NAME} \
    --approve

# Create external-dns-policy if it does not already exist
echo ""
echo "Setting up IAM policy ..."
export IAM_POLICY=$(aws iam get-policy --policy-arn arn:aws:iam::${account}:policy/external-dns-policy)
if [ "$IAM_POLICY" == "" ]; then
        echo "Creating external-dns-policy ..."
        json_out=$(aws iam create-policy --policy-name external-dns-policy --policy-document file://external-dns-policy.json)
        POLICY_ARN=$(echo $json_out | jq -r '.Policy.Arn')
        echo "POLICY_ARN=$POLICY_ARN"
else
        echo "IAM policy external-dns-policy already exists"
        POLICY_ARN=$(echo $IAM_POLICY | jq -r .Policy.Arn)
fi

# Create exernal-dns-role if it does not exist
echo ""
echo "Setting up service account ..."
export ROLE_NAME=external-dns-role
#ROLE=$(aws iam get-role --role-name=${ROLE_NAME})
IAM_SA_NAME=external-dns-sa-${CLUSTER_NAME}
ACCOUNT_EXISTS=$(eksctl get iamserviceaccount --cluster $CLUSTER_NAME | grep ${IAM_SA_NAME} | wc -l)
if [  "$ACCOUNT_EXISTS" == "0" ]; then
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

# Deploy external-dns with helm
echo ""
echo "Deploying externalDNS using helm ..."

# Patch service account
# The following labels and annotations are required by the external-dns helm chart
kubectl -n kube-system patch sa ${IAM_SA_NAME} -p '{"metadata":{"labels":{"app.kubernetes.io/managed-by":"Helm","meta.helm.sh/release-name":"external-dns","meta.helm.sh/release-namespace":"kube-system"}}}'
kubectl -n kube-system patch sa ${IAM_SA_NAME} -p '{"metadata":{"annotations":{"meta.helm.sh/release-name":"external-dns","meta.helm.sh/release-namespace":"kube-system"}}}'

cat<<EOF> values.yaml
provider:
  name: "aws"
env:
  - name: "AWS_DEFAULT_REGION"
    value: "${AWS_REGION}"
serviceAccount:
  creaate: false
  name: "${IAM_SA_NAME}"
EOF

helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
helm repo update
helm upgrade --install external-dns external-dns/external-dns --namespace kube-system --values ./values.yaml --version 1.16.1

echo ""
