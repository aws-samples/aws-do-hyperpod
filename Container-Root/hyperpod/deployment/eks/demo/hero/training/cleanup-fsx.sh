#!/bin/bash

TARGET_NAMESPACE="hyperpod-ns-training-team"

# Delete PVC first
echo "Deleting PVC..."
kubectl delete pvc fsx-claim -n ${TARGET_NAMESPACE}

# Delete PV
echo "Deleting PV..."
kubectl delete pv fsx-pv-${TARGET_NAMESPACE}

# Delete StorageClass
echo "Deleting StorageClass..."
kubectl delete sc fsx-sc-${TARGET_NAMESPACE}

# Verify resources are deleted
echo -e "\nVerifying resources are deleted:"
echo "PVC status:"
kubectl get pvc -n ${TARGET_NAMESPACE} fsx-claim 2>/dev/null || echo "PVC deleted"
echo -e "\nPV status:"
kubectl get pv fsx-pv-${TARGET_NAMESPACE} 2>/dev/null || echo "PV deleted"
echo -e "\nStorageClass status:"
kubectl get sc fsx-sc-${TARGET_NAMESPACE} 2>/dev/null || echo "StorageClass deleted"
