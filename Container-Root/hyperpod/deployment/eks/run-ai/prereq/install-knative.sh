#!/bin/bash

echo ""
echo "Installing Knative ..."

set -e
set -o pipefail

echo ""
echo "Installing Knative CRDs ..."
kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.17.0/serving-crds.yaml

echo ""
echo "Installing Knative Core ..."
kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.17.0/serving-core.yaml

echo ""
echo "Installing Knative Kourier ..."
kubectl apply -f https://github.com/knative/net-kourier/releases/download/knative-v1.17.0/kourier.yaml

echo ""
echo "Configuring Knative networking ..."
kubectl patch configmap/config-network \
        --namespace knative-serving \
        --type merge \
        --patch '{"data":{"ingress-class":"kourier.ingress.networking.knative.dev"}}'

echo ""
echo "Configuring Knative autoscaler ..."
kubectl patch configmap/config-autoscaler \
        --namespace knative-serving \
        --type merge \
        --patch '{"data":{"enable-scale-to-zero":"true"}}'

echo ""
echo "Configuring Knative features to work with Run:ai scheduler ..."
kubectl patch configmap/config-features \
        --namespace knative-serving \
        --type merge \
        --patch '{"data":{"kubernetes.podspec-schedulername":"enabled","kubernetes.podspec-affinity":"enabled","kubernetes.podspec-tolerations":"enabled","kubernetes.podspec-volumes-emptydir":"enabled","kubernetes.podspec-securitycontext":"enabled","kubernetes.containerspec-addcapabilities":"enabled","kubernetes.podspec-persistent-volume-claim":"enabled","kubernetes.podspec-persistent-volume-write":"enabled","multi-container":"enabled","kubernetes.podspec-init-containers":"enabled"}}'

set +e

echo ""

