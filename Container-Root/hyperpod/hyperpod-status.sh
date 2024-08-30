#!/bin/bash

source ./conf/env.conf
source ${CONF}/env_input

echo ""
echo "Status of HyperPod $IMPL cluster ${HYPERPOD_NAME}: "

impl/${IMPL}/hyperpod-status.sh

