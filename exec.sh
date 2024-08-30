#!/bin/bash

######################################################################
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. #
# SPDX-License-Identifier: MIT-0                                     #
######################################################################

source .env

if [ "$1" == "" ]; then
	CMDLN="bash"
else
	CMDLN=$@
fi

CMD="docker container exec -it ${CONTAINER} $CMDLN"
if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

