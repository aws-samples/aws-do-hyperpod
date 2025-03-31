#!/bin/bash

######################################################################
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. #
# SPDX-License-Identifier: MIT-0                                     #
######################################################################

source .env

# Create registry if needed
REGISTRY_COUNT=$(aws ecr describe-repositories | grep \"${IMAGE}\" | wc -l | tr -d ' ')
if [ "$REGISTRY_COUNT" == "0" ]; then
	CMD="aws ecr create-repository --repository-name ${IMAGE}"
	if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
	eval "$CMD"
fi

# Login to registry
./login.sh

# Push image
CMD="docker image push ${REGISTRY}${IMAGE}${TAG}"
if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

CMD="docker image tag ${REGISTRY}${IMAGE}${TAG} ${REGISTRY}${IMAGE}:latest"
if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

CMD="docker image push ${REGISTRY}${IMAGE}:latest"
if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"
