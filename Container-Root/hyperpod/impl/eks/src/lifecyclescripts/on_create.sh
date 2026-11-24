#!/bin/bash

set -ex

LOG_FILE="/var/log/provision/provisioning.log"
mkdir -p "/var/log/provision"
touch $LOG_FILE

# Function to log messages
logger() {
  echo "$@" | tee -a $LOG_FILE
}

logger "[start] on_create.sh"

if [[ $(mount | grep /opt/sagemaker) ]]; then
  logger "Found secondary EBS volume. Setting containerd data root to /opt/sagemaker/containerd/data-root"
  # Do not fail the lifecycle script if the containerd config cannot be updated
  sed -i -e "/^[# ]*root\s*=/c\root = \"/opt/sagemaker/containerd/data-root\"" /etc/eks/containerd/containerd-config.toml || logger "WARNING: could not update the containerd config, continuing"
fi

logger "no more steps to run"
logger "[stop] on_create.sh"