#!/bin/bash

echo ""
echo "Removing Knative ..."

echo ""
echo "Removing Knative Kourier ..."
kubectl delete -f https://github.com/knative/net-kourier/releases/download/knative-v1.17.0/kourier.yaml

echo ""
echo "Removing Knative Core ..."
kubectl delete -f https://github.com/knative/serving/releases/download/knative-v1.17.0/serving-core.yaml

echo ""
echo "Removing Knative CRDs ..."
kubectl delete -f https://github.com/knative/serving/releases/download/knative-v1.17.0/serving-crds.yaml

echo ""
echo "Deleting knative-serving namespace ..."
kubectl delete namespace knative-serving

echo ""

