#!/bin/bash
export TS_NAME=hyperpod-ts-demo

aws sagemaker create-presigned-mlflow-tracking-server-url \
  --tracking-server-name $TS_NAME \
  --session-expiration-duration-in-seconds 1800 \
  --expires-in-seconds 300 \
  --region $AWS_REGION