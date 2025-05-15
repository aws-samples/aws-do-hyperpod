#!/bin/bash

# Ref: https://github.com/cert-manager/cmctl

echo ""
echo "Installing cmctl ..."

export OS=$(uname -s | tr A-Z a-z)
export ARCH=$(uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/')
curl -fsSL -o cmctl https://github.com/cert-manager/cmctl/releases/download/v2.2.0/cmctl_${OS}_${ARCH}
#curl -fsSL -o cmctl https://github.com/cert-manager/cmctl/releases/latest/download/cmctl_${OS}_${ARCH}
chmod +x cmctl
sudo mv cmctl /usr/local/bin
# or `sudo mv cmctl /usr/local/bin/kubectl-cert_manager` to use `kubectl cert-manager` instead.

echo ""
cmctl version
echo ""
