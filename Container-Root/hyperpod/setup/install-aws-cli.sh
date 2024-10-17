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
sudo ./aws/install --update --install-dir /usr/local/aws-cli
sudo ln -s /usr/local/aws-cli/v2/current/dist/aws /usr/local/bin/aws
sudo ln -s /usr/local/aws-cli/v2/current/dist/aws /bin/aws
aws --version
rm -rf ./aws
rm -f awscliv2.zip

# Install Session Manager Plugin
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
sudo dpkg -i session-manager-plugin.deb
rm -f session-manager-plugin.deb

