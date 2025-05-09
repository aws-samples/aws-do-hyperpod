#!/bin/bash

echo ""
echo "Deploying NGINX Ingress Controller ..."

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace

echo ""

