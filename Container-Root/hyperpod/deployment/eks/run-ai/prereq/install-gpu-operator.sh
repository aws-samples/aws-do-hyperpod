#!/bin/bash

# Ref: https://github.com/NVIDIA/gpu-operator/blob/main/deployments/gpu-operator/values.yaml
# Ref: https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/getting-started.html
# Ref: https://docs.run.ai/v2.17/admin/runai-setup/cluster-setup/cluster-prerequisites/#nvidia

echo ""
echo "Installing GPU Operator ..."

helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
helm repo update
helm install --wait gpu-operator -n gpu-operator --create-namespace nvidia/gpu-operator --version=v23.9.2 --set driver.enabled=false --set toolkit.version=v1.14.6-ubi8 --set devicePlugin.enabled=false

echo ""

