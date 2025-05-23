#!/bin/bash

# Ref: https://docs.run.ai/v2.17/admin/runai-setup/cluster-setup/cluster-prerequisites/#prometheus

echo ""
echo "Installing Prometheus ..."

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring --create-namespace --set grafana.enabled=false

echo ""

