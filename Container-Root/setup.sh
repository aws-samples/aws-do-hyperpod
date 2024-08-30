#!/bin/bash

######################################################################
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. #
# SPDX-License-Identifier: MIT-0                                     #
######################################################################

if [ -d /etc/apt ]; then
        [ -n "$http_proxy" ] && echo "Acquire::http::proxy \"${http_proxy}\";" > /etc/apt/apt.conf; \
        [ -n "$https_proxy" ] && echo "Acquire::https::proxy \"${https_proxy}\";" >> /etc/apt/apt.conf; \
        [ -f /etc/apt/apt.conf ] && cat /etc/apt/apt.conf
fi

# Install basic tools
apt-get update -y && apt-get upgrade -y
apt-get install -y curl jq vim nano less unzip git gettext-base groff sudo htop bash-completion wget bc gcc

# Install yq
./hyperpod/setup/install-yq.sh

# Install aws cli
pushd ./hyperpod/setup
./install-aws-cli.sh
popd

# Install eksctl
./hyperpod/setup/eks/install-eksctl.sh

# Install kubectl
./hyperpod/setup/eks/install-kubectl.sh

# Install kubectx
./hyperpod/setup/eks/install-kubectx.sh

# Install kubetail
./hyperpod/setup/eks/install-kubetail.sh

# Install kubeshell
./hyperpod/setup/eks/install-kubeshell.sh

# Install helm
./hyperpod/setup/eks/install-helm.sh

# Install docker
./hyperpod/setup/install-docker.sh

# Install golang
./hyperpod/setup/install-go.sh

# Install python
./hyperpod/setup/install-python.sh
python -m pip install torchx[kubernetes]

# Install monitui
./hyperpod/setup/eks/install-monitui.sh

# Install kubeps1 and configure bashrc aliases 
./hyperpod/setup/eks/install-kubeps1.sh

# Install bash customizations
./hyperpod/setup/install-bashrc.sh

# Install k9s
./hyperpod/setup/eks/install-k9s.sh

# Install hyperpod-eks
./hyperpod/setup/eks/install-hyperpod-eks.sh

# Install sbom utilities
./hyperpod/setup/install-sbom-utils.sh

# Generate SBOM and store it in the root of the container image
./sbom.sh

