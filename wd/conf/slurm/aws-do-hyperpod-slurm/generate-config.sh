#!/bin/bash
# Generate hyperpod-config.json, the request body for
# "aws sagemaker create-cluster --cli-input-json".
# Inputs: ./env_input (desired cluster shape) and ./env_vars (resource IDs
# read from the CloudFormation stacks by create_config.sh).

# Show debug info about the environment files
echo "==== The content of env_input ===="
cat ./env_input
echo "==============================================="
echo "==== The content of env_vars ===="
cat ./env_vars
echo "==============================================="

source ./env_input
source ./env_vars

# Security groups and optional FSx settings
SECURITY_GROUP_IDS="[\"${SECURITY_GROUP_ID}\"]"
FSX_ENABLED=false
if [ "${CREATE_FSX}" == "true" ]; then
    FSX_ENABLED=true
    SECURITY_GROUP_IDS="[\"${SECURITY_GROUP_ID}\", \"${FSX_SECURITY_GROUP_ID}\"]"
fi

jq -n \
    --arg cluster_name "${HYPERPOD_NAME}" \
    --arg node_recovery "${NODE_RECOVERY}" \
    --arg role "${EXECUTION_ROLE}" \
    --arg subnet "${PRIVATE_SUBNET_ID}" \
    --argjson security_groups "${SECURITY_GROUP_IDS}" \
    --argjson fsx_enabled "${FSX_ENABLED}" \
    --arg fsx_dns "${FSX_DNS_NAME}" \
    --arg fsx_mount_name "${FSX_MOUNT_NAME}" \
    --arg fsx_mount_path "${FSX_MOUNT_PATH}" \
    --arg controller_name "${CONTROLLER_GROUP_NAME}" \
    --arg controller_type "${CONTROLLER_INSTANCE_TYPE}" \
    --argjson controller_count "${CONTROLLER_COUNT}" \
    --argjson controller_volume "${CONTROLLER_VOLUME_SIZE}" \
    --arg worker_name "${WORKER_GROUP_NAME}" \
    --arg worker_type "${WORKER_INSTANCE_TYPE}" \
    --argjson worker_count "${WORKER_COUNT}" \
    --argjson worker_volume "${WORKER_VOLUME_SIZE}" \
    --arg partition "${PARTITION_NAME}" \
'
  # Storage: an EBS volume, plus the shared FSx mount when enabled
  def storage($volume):
    [{EbsVolumeConfig: {VolumeSizeInGB: $volume}}]
    + (if $fsx_enabled
       then [{FsxLustreConfig: {DnsName: $fsx_dns, MountName: $fsx_mount_name, MountPath: $fsx_mount_path}}]
       else [] end);

  def group($name; $type; $count; $volume; $slurm):
    {
      InstanceGroupName: $name,
      InstanceType: $type,
      InstanceCount: $count,
      ExecutionRole: $role,
      ThreadsPerCore: 1,
      InstanceStorageConfigs: storage($volume),
      SlurmConfig: $slurm
    };

  {
    ClusterName: $cluster_name,
    NodeProvisioningMode: "Continuous",
    NodeRecovery: $node_recovery,
    InstanceGroups: [
      group($controller_name; $controller_type; $controller_count; $controller_volume;
            {NodeType: "Controller"}),
      group($worker_name; $worker_type; $worker_count; $worker_volume;
            {NodeType: "Compute", PartitionNames: [$partition]})
    ],
    VpcConfig: {SecurityGroupIds: $security_groups, Subnets: [$subnet]},
    Tags: [{Key: "Name", Value: $cluster_name}]
  }
' > hyperpod-config.json

if [ ! -s hyperpod-config.json ]; then
    echo "ERROR: failed to generate hyperpod-config.json"
    exit 1
fi

# Display the generated JSON file
echo "==== Generated hyperpod-config.json ===="
cat hyperpod-config.json
echo "=================================================="
