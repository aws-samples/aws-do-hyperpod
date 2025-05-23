#!/bin/bash

export RUNAI_VERSION=2.20.24
export DNS_NAME=runai-remote.iankouls.do.wwso.aws.dev


echo ""
echo "Installing Run.ai control plane version $RUNAI_VERSION at DNS $DNS_NAME ..."
helm repo add runai-backend https://runai.jfrog.io/artifactory/cp-charts-prod
helm repo update
helm upgrade --install runai-backend -n runai-backend runai-backend/control-plane --version "$RUNAI_VERSION" --set global.domain=$DNS_NAME --set global.ingress.tlsSecretName=runai-backend-tls --set global.customCA.enabled=true

