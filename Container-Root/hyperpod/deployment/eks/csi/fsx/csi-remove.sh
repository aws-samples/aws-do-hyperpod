#!/bin/bash

source .env

echo ""
echo "Removing FSX CSI ..."

echo ""
echo "Deleting storage class ..."
CMD="kubectl delete sc fsx-sc"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "${CMD}"

echo ""
echo "Deleting service account fsx-csi-controller-sa ..."
CMD="eksctl delete iamserviceaccount --name fsx-csi-controller-sa --namespace kube-system --cluster $EKS_CLUSTER_NAME --region $AWS_REGION"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "${CMD}"

echo ""
echo "Deleting FSX CSI driver using helm ..."
CMD="helm delete aws-fsx-csi-driver --namespace kube-system"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "${CMD}"

echo ""
