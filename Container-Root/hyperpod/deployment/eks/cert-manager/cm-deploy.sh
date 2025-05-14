#!/bin/bash

# Ref: https://cert-manager.io/docs/tutorials/getting-started-aws-letsencrypt/

echo ""
echo "Insalling cert-manager ..."

helm install cert-manager cert-manager \
  --repo https://charts.jetstack.io \
  --namespace cert-manager \
  --create-namespace \
  --version v1.17.2 \
  --set crds.enabled=true

