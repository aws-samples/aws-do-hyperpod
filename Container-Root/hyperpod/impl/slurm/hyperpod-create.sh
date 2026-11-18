#!/bin/bash
# Create a HyperPod Slurm cluster:
#   1. create the base stack (VPC, subnets, security group, execution role)
#   2. create the FSx stack (only when CREATE_FSX=true)
#   3. read the stack outputs into env_vars
#   4. generate hyperpod-config.json
#   5. create the HyperPod cluster with the aws cli
# Settings come from conf/env.conf and ${CONF}/env_input, sourced by the caller.

CFN_CREATE=${CFN_CREATE:-/util/cfn-create.sh}

export REGION_OPT=""
if [ ! "${AWS_REGION}" == "" ]; then
	export REGION_OPT="--region ${AWS_REGION}"
fi

# stack_status <stack-name>
# Prints the stack status, or nothing if the stack does not exist.
stack_status() {
	aws cloudformation describe-stacks --stack-name "$1" ${REGION_OPT} \
		--query 'Stacks[0].StackStatus' --output text 2>/dev/null
}

# ensure_stack <stack-name> <template-file> <parameters-template> <parameters-file>
# Creates the stack unless it already exists in CREATE_COMPLETE.
# Stops the script if the stack is in any other state, or if creation fails.
ensure_stack() {
	local stack=$1 template=$2 params_template=$3 params_file=$4
	local status
	status=$(stack_status "${stack}")
	if [ "${status}" == "CREATE_COMPLETE" ] || [ "${status}" == "UPDATE_COMPLETE" ]; then
		echo "CloudFormation stack ${stack} already exists (${status})"
		return 0
	fi
	if [ -n "${status}" ]; then
		echo "[ERROR] CloudFormation stack ${stack} is in state ${status}. Resolve it, then run again."
		return 1
	fi
	# Create parameter file from the template and the current environment
	cat ${params_template} | envsubst > ${params_file}
	echo "Creating CloudFormation stack ${stack} ..."
	${CFN_CREATE} ${stack} ${template} file://${params_file}
	# The wait in cfn-create.sh does not set an exit status we can rely on, so check the result
	status=$(stack_status "${stack}")
	if [ "${status}" != "CREATE_COMPLETE" ]; then
		echo "[ERROR] CloudFormation stack ${stack} ended in state '${status}'"
		return 1
	fi
}

echo ""
echo "Creating HyperPod Slurm cluster ${HYPERPOD_NAME} ..."

pushd ${ENV_HOME}impl/slurm/src > /dev/null || exit 1

# 1. Base stack
ensure_stack ${STACK_ID} cfn/hyperpod-slurm-base.yaml cfn/base-parameters.json-template ${ENV_HOME}${CONF}/base-parameters.json || exit 1

# 2. FSx stack
if [ "${CREATE_FSX}" == "true" ]; then
	ensure_stack ${FSX_STACK_ID} cfn/hyperpod-slurm-fsx.yaml cfn/fsx-parameters.json-template ${ENV_HOME}${CONF}/fsx-parameters.json || exit 1
else
	echo "CREATE_FSX is not true, skipping FSx stack"
fi

# 3. Extract output environment variables
scripts/create_config.sh
if [ "$?" != "0" ]; then
	echo "[ERROR] failed to read stack outputs"
	exit 1
fi
mv env_vars ${ENV_HOME}${CONF}
popd > /dev/null

# 4. Generate HyperPod config
pushd ${ENV_HOME}${CONF} > /dev/null || exit 1
echo "Generating HyperPod config ..."
./generate-config.sh
if [ "$?" != "0" ]; then
	echo "[ERROR] failed to generate hyperpod-config.json"
	exit 1
fi

# 5. Create HyperPod cluster
echo "Creating HyperPod cluster ..."
CMD="aws sagemaker create-cluster --cli-input-json file://hyperpod-config.json ${REGION_OPT} ${ENDPOINT_ARG}"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"
if [ "$?" == "0" ]; then
	echo ""
	echo "To monitor cluster status use:"
	echo "watch ./hyperpod-status.sh"
	echo ""
fi
popd > /dev/null
