#!/bin/bash

# Ref: https://cert-manager.io/docs/tutorials/getting-started-aws-letsencrypt/

echo ""
echo "cert-manager status ..."

kubectl get all --namespace cert-manager

