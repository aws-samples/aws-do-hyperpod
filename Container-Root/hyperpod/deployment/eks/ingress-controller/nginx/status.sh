#!/bin/bash

echo ""
echo "NGINX Ingress Controller Status ..."

helm list --namespace ingress-nginx

echo ""
kubectl get ingressclass,pods,services --namespace ingress-nginx

echo ""

