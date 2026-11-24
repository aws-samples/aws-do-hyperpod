#!/bin/bash
# Enable Karpenter autoscaling on a HyperPod EKS cluster:
#   1. wait for the cluster to be InService
#   2. create the IAM policy for autoscaling, if it does not exist
#   3. attach the policy to the execution role
#   4. update the trust policy of the execution role
#   5. enable autoscaling with "aws sagemaker update-cluster"
#   6. wait for autoscaling to be InService
#   7. apply the Karpenter NodeClass and NodePool
# Safe to run more than once.
#
# Settings come from the environment. When run on its own from /hyperpod,
# they are read from conf/env.conf, ${CONF}/env_input and ${CONF}/env_vars.
# Note: step 4 replaces the whole trust policy of the execution role.

POLICY_NAME=${POLICY_NAME:-SageMakerHyperPodKarpenterPolicy}
NODECLASS_NAME=nodeclass-default
POLL_INTERVAL=${POLL_INTERVAL:-30}
POLL_MAX=${POLL_MAX:-120}
# IAM changes can take a while to become visible to HyperPod
RETRY_INTERVAL=${RETRY_INTERVAL:-15}
RETRY_MAX=${RETRY_MAX:-12}

if [ -z "${HYPERPOD_NAME}" ]; then
	source conf/env.conf
	source ${CONF}/env_input
	source ${CONF}/env_vars
fi
MANIFESTS_DIR=${MANIFESTS_DIR:-${ENV_HOME}impl/eks/src/manifests}

REGION_OPT=""
if [ ! "${AWS_REGION}" == "" ]; then
	REGION_OPT="--region ${AWS_REGION}"
fi

# run <command> - show the command when VERBOSE is not false, then run it
run() {
	if [ ! "$VERBOSE" == "false" ]; then echo -e "\n$1\n" >&2; fi
	eval "$1"
}

# describe_cluster <query> - print one value of describe-cluster
describe_cluster() {
	aws sagemaker describe-cluster --cluster-name ${HYPERPOD_NAME} --query "$1" --output text ${REGION_OPT} ${ENDPOINT_ARG} 2>/dev/null
}

# check_settings - stop if a required setting is missing
check_settings() {
	local name
	for name in HYPERPOD_NAME EXECUTION_ROLE AUTOSCALE_GROUP_NAME AUTOSCALE_CPU_LIMIT; do
		if [ -z "${!name}" ]; then
			echo "[ERROR] ${name} is not set"
			return 1
		fi
	done
	# EXECUTION_ROLE looks like arn:aws:iam::<account>:role/<path>/<name>
	ROLE_NAME=${EXECUTION_ROLE##*/}
	ACCOUNT_ID=$(echo "${EXECUTION_ROLE}" | cut -d: -f5)
	if [ -z "${ROLE_NAME}" ] || [ -z "${ACCOUNT_ID}" ]; then
		echo "[ERROR] could not read the role name and account from EXECUTION_ROLE=${EXECUTION_ROLE}"
		return 1
	fi
	POLICY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy/${POLICY_NAME}"
}

# wait_for_cluster - wait until the cluster is InService and has the autoscaling instance group
wait_for_cluster() {
	local count=0 status
	echo "Waiting for HyperPod cluster ${HYPERPOD_NAME} to be InService ..."
	while true; do
		status=$(describe_cluster ClusterStatus)
		if [ "${status}" == "InService" ]; then break; fi
		if [ -z "${status}" ] || [ "${status}" == "Failed" ] || [ "${status}" == "RollingBack" ]; then
			echo "[ERROR] cluster ${HYPERPOD_NAME} is in state '${status}'"
			return 1
		fi
		count=$((count + 1))
		if [ "$count" -gt "${POLL_MAX}" ]; then
			echo "[ERROR] timed out waiting for cluster ${HYPERPOD_NAME}, last state '${status}'"
			return 1
		fi
		echo "Cluster status is ${status}, checking again in ${POLL_INTERVAL} sec ..."
		sleep ${POLL_INTERVAL}
	done
	# Autoscaling needs continuous provisioning and the instance group that Karpenter scales
	if [ "$(describe_cluster NodeProvisioningMode)" != "Continuous" ]; then
		echo "[ERROR] autoscaling needs NodeProvisioningMode Continuous on cluster ${HYPERPOD_NAME}"
		return 1
	fi
	if [ -z "$(describe_cluster "InstanceGroups[?InstanceGroupName=='${AUTOSCALE_GROUP_NAME}'].InstanceGroupName")" ]; then
		echo "[ERROR] instance group ${AUTOSCALE_GROUP_NAME} does not exist in cluster ${HYPERPOD_NAME}"
		echo "        Create the cluster with ENABLE_AUTOSCALING=true, or add the group first."
		return 1
	fi
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

# enable_autoscaling - turn on Karpenter autoscaling, unless it is already on
enable_autoscaling() {
	# The cluster role cannot be updated while autoscaling is enabled
	if [ "$(describe_cluster AutoScaling.Mode)" == "Enable" ]; then
		echo "Autoscaling is already enabled on cluster ${HYPERPOD_NAME}"
		return 0
	fi
	echo "Enabling autoscaling on cluster ${HYPERPOD_NAME} ..."
	# The role changes made just before can take a while to be visible to HyperPod.
	# Retry while the error says the role does not have sufficient permissions.
	local out attempt=0
	while true; do
		out=$(run "aws sagemaker update-cluster --cluster-name ${HYPERPOD_NAME} --auto-scaling '{\"Mode\":\"Enable\",\"AutoScalerType\":\"Karpenter\"}' --cluster-role ${EXECUTION_ROLE} ${REGION_OPT} ${ENDPOINT_ARG} 2>&1")
		if [ "$?" == "0" ]; then
			echo "${out}"
			return 0
		fi
		attempt=$((attempt + 1))
		if echo "${out}" | grep -q "does not have sufficient permissions" && [ "$attempt" -le "${RETRY_MAX}" ]; then
			echo "The role changes are not visible to HyperPod yet, retrying in ${RETRY_INTERVAL} sec (attempt ${attempt} of ${RETRY_MAX}) ..."
			sleep ${RETRY_INTERVAL}
			continue
		fi
		echo "${out}"
		echo "[ERROR] failed to enable autoscaling on cluster ${HYPERPOD_NAME}"
		return 1
	done
}

# wait_for_autoscaling - wait until the autoscaling status is InService
wait_for_autoscaling() {
	local count=0 status
	echo "Waiting for autoscaling to be InService ..."
	while true; do
		status=$(describe_cluster AutoScaling.Status)
		if [ "${status}" == "InService" ]; then
			echo "Autoscaling is InService"
			return 0
		fi
		if [ "${status}" == "Failed" ]; then
			echo "[ERROR] autoscaling failed: $(describe_cluster AutoScaling.FailureMessage)"
			return 1
		fi
		count=$((count + 1))
		if [ "$count" -gt "${POLL_MAX}" ]; then
			echo "[ERROR] timed out waiting for autoscaling, last status '${status}'"
			return 1
		fi
		echo "Autoscaling status is '${status}', checking again in ${POLL_INTERVAL} sec ..."
		sleep ${POLL_INTERVAL}
	done
}

# apply_manifests - create the Karpenter NodeClass and NodePool and wait for the NodeClass to be Ready
apply_manifests() {
	local template count=0 ready
	for template in karpenter-nodeclass karpenter-nodepool; do
		if [ ! -f ${MANIFESTS_DIR}/${template}.yaml-template ]; then
			echo "[ERROR] ${MANIFESTS_DIR}/${template}.yaml-template not found"
			return 1
		fi
		envsubst '${AUTOSCALE_GROUP_NAME} ${AUTOSCALE_CPU_LIMIT}' < ${MANIFESTS_DIR}/${template}.yaml-template > ${WORK_DIR}/${template}.yaml
		echo "Applying ${template} ..."
		run "kubectl apply -f ${WORK_DIR}/${template}.yaml"
		if [ "$?" != "0" ]; then
			echo "[ERROR] failed to apply ${template}"
			return 1
		fi
	done
	echo "Waiting for NodeClass ${NODECLASS_NAME} to be Ready ..."
	while true; do
		ready=$(kubectl get hyperpodnodeclass ${NODECLASS_NAME} -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
		if [ "${ready}" == "True" ]; then
			echo "NodeClass ${NODECLASS_NAME} is Ready"
			return 0
		fi
		count=$((count + 1))
		if [ "$count" -gt "${POLL_MAX}" ]; then
			echo "[ERROR] timed out waiting for NodeClass ${NODECLASS_NAME} to be Ready"
			return 1
		fi
		sleep ${POLL_INTERVAL}
	done
}

WORK_DIR=$(mktemp -d)
trap 'rm -rf "${WORK_DIR}"' EXIT

echo ""
echo "Enabling autoscaling on HyperPod cluster ${HYPERPOD_NAME} ..."
check_settings || exit 1
wait_for_cluster || exit 1
create_policy || exit 1
attach_policy || exit 1
update_trust_policy || exit 1
enable_autoscaling || exit 1
wait_for_autoscaling || exit 1
apply_manifests || exit 1
echo ""
echo "Autoscaling is enabled. Karpenter will add nodes to ${AUTOSCALE_GROUP_NAME} when pods are pending."
echo ""
