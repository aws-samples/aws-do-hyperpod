#!/bin/bash

export MLFLOW_ROLE_ARN=$(aws iam get-role --role-name $MLFLOW_ROLE_NAME --query 'Role.Arn' --output text)
export TS_NAME=hyperpod-ts-demo
export MLFLOW_VERSION=3.0

# 2. Use AWS CLI to create Tracking Server
aws sagemaker create-mlflow-tracking-server \
 --tracking-server-name $TS_NAME \
 --artifact-store-uri s3://$S3_BUCKET_NAME \
 --role-arn $MLFLOW_ROLE_ARN \
 --automatic-model-registration \
 --region $AWS_REGION \
 --mlflow-version $MLFLOW_VERSION


 