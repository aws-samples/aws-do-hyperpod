#!/bin/bash

##/usr/bin/env bash

#set -e
#set -o pipefail

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <STACK_NAME> <TEMPLATE_FILE> [<PARAMETERS>]"
    exit 1
  fi

# Create cloudformation template
STACK_NAME=$1
TEMPLATE_FILE=$2
shift
shift

echo "Deploying stack: $STACK_NAME"
echo "Using template: $TEMPLATE_FILE"
echo "Parameters: $@"

aws cloudformation create-stack \
  --stack-name $STACK_NAME \
  --template-body file://$TEMPLATE_FILE \
  --parameters "$@" \
  --capabilities "CAPABILITY_IAM" "CAPABILITY_NAMED_IAM"

# Wait for cloudformation template to complete
aws cloudformation wait stack-create-complete --stack-name $STACK_NAME

