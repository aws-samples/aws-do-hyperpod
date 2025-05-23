#!/bin/bash

echo ""
echo "Removing Run:ai cluster ..."

helm uninstall runai-cluster -n runai

echo ""
echo "Removing runaiconfig finalizer ..."
kubectl patch runaiconfig runai -n runai -p '{"metadata":{"finalizers":null}}' --type=merge

echo ""
echo "Removing runaiconfig runai ..."
kubectl delete runaiconfig runai -n runai

echo ""

