#!/bin/bash

source ./conf/env.conf
source ${CONF}/env_input

echo ""
echo "List of $IMPL clusters: "

impl/${IMPL}/cluster-list.sh

