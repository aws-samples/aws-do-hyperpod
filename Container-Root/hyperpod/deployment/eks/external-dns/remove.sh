#!/bin/bash

export CLUSTER_NAME=$(kubectl config current-context | cut -d '/' -f 2)
export IAM_SA_NAME=external-dns-sa-${CLUSTER_NAME}

# This removes the external-dns deployment and service account, but leaves the iam policy and role in place

echo ""
echo "Uninstalling helm chart ..."
helm -n kube-system uninstall external-dns

echo ""
echo "Deleting service account ..."
eksctl delete iamserviceaccount --cluster=${CLUSTER_NAME} --namespace=kube-system --name=${IAM_SA_NAME}

