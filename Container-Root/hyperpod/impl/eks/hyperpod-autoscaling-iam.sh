#!/bin/bash
# Prepare the IAM setup that HyperPod autoscaling (Karpenter) needs. Run it before
# "aws sagemaker create-cluster" with AutoScaling enabled:
#   1. create the IAM policy for autoscaling, if it does not exist
#   2. attach the policy to the execution role
#   3. update the trust policy of the execution role
# Safe to run more than once. It does not touch the cluster.
#
# Settings come from the environment. When run on its own from /hyperpod,
# they are read from conf/env.conf, ${CONF}/env_input and ${CONF}/env_vars.
# Note: step 3 replaces the whole trust policy of the execution role.
POLICY_NAME=${POLICY_NAME:-SageMakerHyperPodKarpenterPolicy}
if [ -z "${EXECUTION_ROLE}" ]; then
	source conf/env.conf
	source ${CONF}/env_input
	source ${CONF}/env_vars
fi
# run <command> - show the command when VERBOSE is not false, then run it
run() {
	if [ ! "$VERBOSE" == "false" ]; then echo -e "\n$1\n" >&2; fi
	eval "$1"
}
# check_settings - stop if the execution role is missing or malformed
check_settings() {
	if [ -z "${EXECUTION_ROLE}" ]; then
		echo "[ERROR] EXECUTION_ROLE is not set"
		return 1
	fi
	# EXECUTION_ROLE looks like arn:aws:iam::<account>:role/<path>/<name>
	ROLE_NAME=${EXECUTION_ROLE##*/}
	ACCOUNT_ID=$(echo "${EXECUTION_ROLE}" | cut -d: -f5)
	if [ -z "${ROLE_NAME}" ] || [ -z "${ACCOUNT_ID}" ]; then
		echo "[ERROR] could not read the role name and account from EXECUTION_ROLE=${EXECUTION_ROLE}"
		return 1
	fi
	POLICY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy/${POLICY_NAME}"
}
# create_policy - create the IAM policy unless it exists
create_policy() {
	local out
	echo "Checking IAM policy ${POLICY_NAME} ..."
	out=$(run "aws iam get-policy --policy-arn ${POLICY_ARN} 2>&1")
	if [ "$?" == "0" ]; then
		echo "IAM policy ${POLICY_NAME} already exists"
		return 0
	fi
	if ! echo "${out}" | grep -q "NoSuchEntity"; then
		echo "[ERROR] failed to look up IAM policy ${POLICY_NAME}:"
		echo "${out}"
		return 1
	fi
	cat > ${WORK_DIR}/policy.json << 'EOP'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sagemaker:BatchAddClusterNodes",
                "sagemaker:BatchDeleteClusterNodes"
            ],
            "Resource": "arn:aws:sagemaker:*:*:cluster/*",
            "Condition": {
                "StringEquals": {
                    "aws:ResourceAccount": "${aws:PrincipalAccount}"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "kms:CreateGrant",
                "kms:DescribeKey"
            ],
            "Resource": "arn:aws:kms:*:*:key/*",
            "Condition": {
                "StringLike": {
                    "kms:ViaService": "sagemaker.*.amazonaws.com"
                },
                "Bool": {
                    "kms:GrantIsForAWSResource": "true"
                },
                "ForAllValues:StringEquals": {
                    "kms:GrantOperations": [
                        "CreateGrant",
                        "Decrypt",
                        "DescribeKey",
                        "GenerateDataKeyWithoutPlaintext",
                        "ReEncryptTo",
                        "ReEncryptFrom",
                        "RetireGrant"
                    ]
                }
            }
        }
    ]
}
EOP
	echo "Creating IAM policy ${POLICY_NAME} ..."
	run "aws iam create-policy --policy-name ${POLICY_NAME} --policy-document file://${WORK_DIR}/policy.json --query Policy.Arn --output text"
	if [ "$?" != "0" ]; then
		echo "[ERROR] failed to create IAM policy ${POLICY_NAME}"
		return 1
	fi
}

# attach_policy - attach the IAM policy to the execution role
attach_policy() {
	echo "Attaching ${POLICY_NAME} to role ${ROLE_NAME} ..."
	run "aws iam attach-role-policy --role-name ${ROLE_NAME} --policy-arn ${POLICY_ARN}"
	if [ "$?" != "0" ]; then
		echo "[ERROR] failed to attach IAM policy to role ${ROLE_NAME}"
		return 1
	fi
}

# update_trust_policy - let HyperPod assume the execution role
update_trust_policy() {
	cat > ${WORK_DIR}/trust-policy.json << 'EOT'
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": [
                    "pods.eks.amazonaws.com",
                    "sagemaker.amazonaws.com",
                    "hyperpod.sagemaker.amazonaws.com"
                ]
            },
            "Action": [
                "sts:AssumeRole",
                "sts:TagSession"
            ]
        }
    ]
}
EOT
	echo "Updating the trust policy of role ${ROLE_NAME} ..."
	run "aws iam update-assume-role-policy --role-name ${ROLE_NAME} --policy-document file://${WORK_DIR}/trust-policy.json"
	if [ "$?" != "0" ]; then
		echo "[ERROR] failed to update the trust policy of role ${ROLE_NAME}"
		return 1
	fi
}

WORK_DIR=$(mktemp -d)
trap 'rm -rf "${WORK_DIR}"' EXIT
echo ""
echo "Preparing IAM for HyperPod autoscaling on role ${EXECUTION_ROLE} ..."
check_settings || exit 1
create_policy || exit 1
attach_policy || exit 1
update_trust_policy || exit 1
echo "IAM setup for autoscaling is done"
echo ""
