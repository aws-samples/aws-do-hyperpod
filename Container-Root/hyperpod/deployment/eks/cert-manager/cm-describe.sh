#!/bin/bash

# Ref: https://cert-manager.io/docs/tutorials/getting-started-aws-letsencrypt/

echo ""
echo "Describing CRDs ..."

echo ""
kubectl explain Issuer

echo ""
kubectl explain CertificateRequest

echo ""
kubectl explain Certificate

