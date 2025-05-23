#!/bin/bash

echo ""
echo "Removing nginx-ingress-controller ..."

helm uninstall ingress-nginx --namespace ingress-nginx

echo ""

