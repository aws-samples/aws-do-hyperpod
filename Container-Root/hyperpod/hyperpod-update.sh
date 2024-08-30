#!/bin/bash

source conf/env.conf
source ${CONF}/env_input

echo ""
echo "Updating HyperPod $IMPL cluster ${HYPERPOD_NAME}: "
echo ""

impl/${IMPL}/hyperpod-update.sh

