#!/bin/bash

echo ""
echo "Removing NGINX Ingress Controller ..."

helm uninstall ingress-nginx --namespace ingress-nginx

echo ""

