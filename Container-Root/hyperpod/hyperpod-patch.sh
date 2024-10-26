#!/bin/bash

source conf/env.conf
source ${CONF}/env_input
source ${CONF}/env_vars

if [ ! "$1" == "" ]; then export HYPERPOD_NAME=$1; fi

echo ""
echo "Patching HyperPod $IMPL cluster ${HYPERPOD_NAME}: "

impl/${IMPL}/hyperpod-patch.sh ${HYPERPOD_NAME}

