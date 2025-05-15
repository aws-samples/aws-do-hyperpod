#!/bin/bash

# Reference: https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html

# This script removes the controller and leaves the policy and role in place

helm uninstall aws-load-balancer-controller --namespace kube-system

