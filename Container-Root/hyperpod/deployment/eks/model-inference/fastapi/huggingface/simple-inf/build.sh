#!/bin/bash

source .env

# Build Docker image
CMD="docker image build --progress=plain ${BUILD_OPTS} -t ${REGISTRY}${IMAGE}${TAG} ."
echo -e "\n${CMD}\n"
eval "$CMD"

