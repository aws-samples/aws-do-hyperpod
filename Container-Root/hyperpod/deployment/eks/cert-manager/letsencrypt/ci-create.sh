#!/bin/bash

export CLUSTER=$(kubectl config current-context | cut -d '/' -f 2)
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
export AWS_DEFAULT_REGION=$(aws configure get region)
export EMAIL_ADDRESS="name@domain.com"

echo ""
echo "Creating ClusterIssuer ..."
envsubst < clusterissuer.yaml-template > clusterissuer.yaml
kubectl apply -f ./clusterissuer.yaml

