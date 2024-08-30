#!/bin/bash

source ./conf/env.conf
source ${CONF}/env_input

echo ""
echo "Configuring HyperPod $IMPL cluster ${HYPERPOD_NAME} ... "

CMD="ls -alh $CONF"

if [ !"$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi

eval "$CMD"

CMD="$EDITOR $CONF/env_input"

if [ !"$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi

eval "$CMD"

