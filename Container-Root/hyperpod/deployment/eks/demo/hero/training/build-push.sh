#!/bin/bash
echo "Building HPTO FSDP image..."
pushd ./training/fsdp/
if docker build --platform linux/amd64 -f Dockerfile -t ${REGISTRY}${IMAGE}:${TAG} .; then
    popd
    echo "Done building image!"
    echo ""
    echo "Pushing image to ECR..."
    
    # Create registry if needed
    if ! aws ecr describe-repositories --repository-names ${IMAGE} >/dev/null 2>&1; then
        echo "Creating ECR repository ${IMAGE}..."
        aws ecr create-repository --repository-name ${IMAGE}
    else
        echo "ECR repository ${IMAGE} already exists."
    fi

    # Login to registry
    echo "Logging in to $REGISTRY ..."
    if aws ecr get-login-password | docker login --username AWS --password-stdin $REGISTRY; then
        # Push image to registry
        if docker image push ${REGISTRY}${IMAGE}:${TAG}; then
            echo "Done pushing image!"
            echo ""
        else
            echo "Failed to push image!"
            exit 1
        fi
    else
        echo "Failed to login to registry!"
        exit 1
    fi
else
    popd
    echo "Failed to build image!"
    exit 1
fi