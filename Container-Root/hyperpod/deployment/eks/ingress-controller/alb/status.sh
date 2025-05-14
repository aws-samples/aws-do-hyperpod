#!/bin/bash

# Reference: https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html

echo ""
echo "AWS Load Balancer Controller status ..."

echo ""
helm list --namespace kube-system | grep aws-load-balancer-controller

echo ""
kubectl get pods -n kube-system -o wide | grep aws-load-balancer

echo ""
