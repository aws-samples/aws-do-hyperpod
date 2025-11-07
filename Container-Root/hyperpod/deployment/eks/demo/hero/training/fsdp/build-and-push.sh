#!/bin/bash

# Set variables
AWS_ACCOUNT_ID="011528295005"
AWS_REGION="us-east-1"
REPOSITORY_NAME="fsdp"
IMAGE_TAG="pytorch2.7.1"
REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# Get the login token and login to ECR
echo "Logging in to Amazon ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${REGISTRY}

# Create ECR repository if it doesn't exist
echo "Creating ECR repository if it doesn't exist..."
aws ecr create-repository --repository-name ${REPOSITORY_NAME} --region ${AWS_REGION} 2>/dev/null || echo "Repository already exists"

# Build the Docker image for AMD64 platform (to match your Kubernetes nodes)
echo "Building Docker image for linux/amd64 platform..."
docker buildx build --platform linux/amd64 -t ${REGISTRY}/${REPOSITORY_NAME}:${IMAGE_TAG} . --load

# Push the image to ECR
echo "Pushing image to ECR..."
docker push ${REGISTRY}/${REPOSITORY_NAME}:${IMAGE_TAG}

echo "Build and push completed successfully!"
echo "Image URI: ${REGISTRY}/${REPOSITORY_NAME}:${IMAGE_TAG}"