#!/bin/bash

echo ""
echo "Run:ai cluster status ..." 

kubectl get cm runai-public -n runai -o jsonpath='{.data}' | yq -P

echo ""

