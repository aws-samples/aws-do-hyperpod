#!/bin/bash

echo ""
echo "Installing nginx-ingress-controller ..."

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx --create-namespace --set controller.extraArgs.default-ssl-certificate=ingress-nginx/nginx-tls

echo ""
