#!/bin/bash

echo ""
echo "Removing Prometheus ..."

helm uninstall prometheus -n monitoring

echo ""

