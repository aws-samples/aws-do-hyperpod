#!/bin/bash
echo "Building HPTO FSDP image..."
pushd ./training/fsdp/
docker build --platform linux/amd64 -f Dockerfile -t ${REGISTRY}${IMAGE}:${TAG} .
popd

echo "Done building image!"
echo ""
echo "Pushing image to ECR..."
# Create registry if needed
REGISTRY_COUNT=$(aws ecr describe-repositories | grep \"${IMAGE}\" | wc -l)
if [ "$REGISTRY_COUNT" == "0" ]; then
        aws ecr create-repository --repository-name ${IMAGE}
fi

# Login to registry
echo "Logging in to $REGISTRY ..."
aws ecr get-login-password | docker login --username AWS --password-stdin $REGISTRY

# Push image to registry
docker image push ${REGISTRY}${IMAGE}:${TAG}
echo "Done pushing image!"
echo ""