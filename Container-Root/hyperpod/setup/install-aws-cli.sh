#!/bin/bash

echo ""
echo "Installing AWS CLI ..."

ARCH=$(uname -m)
OS=$(uname -s)
OS_LOWER=$(echo $OS | tr '[:upper:]' '[:lower:]')
PLATFORM=${OS_LOWER}-${ARCH}
URL=https://awscli.amazonaws.com/awscli-exe-${PLATFORM}.zip
echo "$URL"

# Install aws cli
curl "$URL" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
sudo cp -f /usr/local/bin/aws /bin/aws
aws --version
rm -rf ./aws
rm -f awscliv2.zip

# Add HyperPod EKS Beta model
aws configure add-model \
  --service-model file://sagemaker/sagemaker-2017-07-24.normal.json \
  --service-name sagemaker-beta

