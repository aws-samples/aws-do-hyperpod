#!/bin/bash

# Ensure runai-reg-creds.yaml is applied to the runai namespace
kubectl get secret -n runai | grep runai-reg-creds

export RUNAI_VERSION=2.20.24
export DNS_NAME=$DNS_NAME
export CLIENT_SECRET=$CLIENT_SECRET
export CLUSTER_UID=$CLUSTER_UID
export CLUSTER_URL=$CLUSTER_URL

echo ""
echo "Installing Run:ai remote cluster version ${RUNAI_VERSION} at $CLUSTER_URL"
echo "on control plane https://$DNS_NAME ..."

helm repo add runai https://runai.jfrog.io/artifactory/api/helm/run-ai-charts --force-update
helm repo update
helm upgrade -i runai-cluster runai/runai-cluster -n runai \
--set controlPlane.url=${DNS_NAME} \
--set controlPlane.clientSecret=${CLIENT_SECRET} \
--set cluster.uid=${CLUSTER_UID} \
--set cluster.url=${CLUSTER_URL} \
--set global.customCA.enabled=true \
--version="${RUNAI_VERSION}" --create-namespace

echo ""

