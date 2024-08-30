#!/bin/bash

# Install python3.9
apt update
apt install -y software-properties-common python3-distutils python3-apt
DEBIAN_FRONTEND=noninteractive; add-apt-repository -y ppa:deadsnakes/ppa; apt install -y python3.10-dev; update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1

# Install pip
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py; python3 ./get-pip.py; rm -f get-pip.py

