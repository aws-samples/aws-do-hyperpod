#!/bin/bash

source ./conf/env.conf
source ${CONF}/env_input

echo ""
echo "List of HyperPod $IMPL clusters: "

impl/${IMPL}/hyperpod-list.sh



