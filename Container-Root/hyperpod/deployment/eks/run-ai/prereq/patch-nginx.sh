#!/bin/bash

echo ""
echo "Patching nginx-ingress-controller service ..."

kubectl -n ingress-nginx patch service ingress-nginx-controller -p '{"spec": {"type": "ClusterIP"}}'

echo ""
