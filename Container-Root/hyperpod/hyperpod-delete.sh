#!/bin/bash

source conf/env.conf
source ${CONF}/env_input
source ${CONF}/env_vars

echo ""
echo "Deleting HyperPod $IMPL cluster ${HYPERPOD_NAME}: "

impl/${IMPL}/hyperpod-delete.sh

