#!/bin/bash
# Read the outputs of the CloudFormation stacks and write them to ./env_vars
# as export statements. The caller sources env_vars afterwards.
#
# Inputs (environment): STACK_ID, AWS_REGION, CREATE_FSX, FSX_STACK_ID
# Output: ./env_vars in the current directory

# stack_output <stack-name> <output-key>
# Prints the value, or nothing if the stack or output does not exist.
stack_output() {
    aws cloudformation describe-stacks --stack-name "$1" \
        --query "Stacks[0].Outputs[?OutputKey=='$2'].OutputValue" \
        --output text ${REGION_OPT} 2>/dev/null
}

# write_var <variable-name> <stack-name> <output-key>
# Reads a stack output, stops with an error if it is empty, then appends an
# export statement to env_vars.
write_var() {
    local name=$1 stack=$2 key=$3
    local value
    value=$(stack_output "$stack" "$key")
    if [[ -z "$value" || "$value" == "None" ]]; then
        echo "[ERROR] failed to retrieve $name (stack: $stack, output: $key)"
        exit 1
    fi
    echo "export ${name}=${value}" >> env_vars
    echo "[INFO] ${name} = ${value}"
}

# Clear previously set env_vars
> env_vars

# Define AWS Region
if [ -z "${AWS_REGION}" ]; then
    echo "[WARNING] AWS_REGION environment variable is not set, using the aws cli default region."
    export AWS_REGION=$(aws configure get region)
fi
REGION_OPT="--region ${AWS_REGION}"
echo "export AWS_REGION=${AWS_REGION}" >> env_vars
echo "[INFO] AWS_REGION = ${AWS_REGION}"

if [ -z "${STACK_ID}" ]; then
    echo "[ERROR] STACK_ID is not set"
    exit 1
fi

# Base stack outputs
write_var VPC_ID             "${STACK_ID}" VpcId
write_var PRIVATE_SUBNET_ID  "${STACK_ID}" PrivateSubnetId
write_var SECURITY_GROUP_ID  "${STACK_ID}" ClusterSecurityGroupId
write_var EXECUTION_ROLE     "${STACK_ID}" ExecutionRoleArn

# FSx stack outputs
if [ "${CREATE_FSX}" == "true" ]; then
    if [ -z "${FSX_STACK_ID}" ]; then
        echo "[ERROR] CREATE_FSX=true but FSX_STACK_ID is not set"
        exit 1
    fi
    write_var FSX_FILE_SYSTEM_ID    "${FSX_STACK_ID}" FileSystemId
    write_var FSX_DNS_NAME          "${FSX_STACK_ID}" FsxDnsName
    write_var FSX_MOUNT_NAME        "${FSX_STACK_ID}" FsxMountName
    write_var FSX_SECURITY_GROUP_ID "${FSX_STACK_ID}" FsxSecurityGroupId
fi
