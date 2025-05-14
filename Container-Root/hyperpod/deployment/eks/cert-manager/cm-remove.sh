#!/bin/bash

# Ref: https://cert-manager.io/docs/tutorials/getting-started-aws-letsencrypt/

echo ""
echo "Removing cert-manager ..."

helm -n cert-manager uninstall cert-manager 

