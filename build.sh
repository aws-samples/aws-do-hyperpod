#!/bin/bash

######################################################################
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. #
# SPDX-License-Identifier: MIT-0                                     #
######################################################################

source .env

echo "aws-do-hyperpod shell $VERSION" > Container-Root/version.txt

# Build Docker image
CMD="docker image build ${BUILD_OPTS} -t ${REGISTRY}${IMAGE}${TAG} ."

if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi

eval "$CMD"

