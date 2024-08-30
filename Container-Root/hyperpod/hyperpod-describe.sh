#!/bin/bash

source ./conf/env.conf
source ${CONF}/env_input

echo ""
echo "Description of HyperPod $IMPL cluster ${HYPERPOD_NAME}: "

impl/${IMPL}/hyperpod-describe.sh

