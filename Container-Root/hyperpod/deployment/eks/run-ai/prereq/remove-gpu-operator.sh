#!/bin/bash

echo ""
echo "Removing GPU Operator ..."

helm uninstall gpu-operator -n gpu-operator

echo ""

