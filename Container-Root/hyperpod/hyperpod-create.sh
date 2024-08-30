#!/bin/bash

source conf/env.conf
source ${CONF}/env_input

echo ""
echo "Creating HyperPod $IMPL cluster ${HYPERPOD_NAME} ..."

impl/${IMPL}/hyperpod-create.sh

