#!/bin/bash

source ./conf/env.conf
source ${CONF}/env_input

echo ""
echo "Describe $IMPL cluster: $1"

impl/${IMPL}/cluster-describe.sh $1

