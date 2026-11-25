#!/bin/bash

# Show debug info about the environment files
echo "==== The content of env_input ===="
cat ./env_input
echo "==============================================="

echo "==== The content of env_vars ===="
cat ./env_vars
echo "==============================================="

source ./env_input
source ./env_vars
# With autoscaling, the cluster starts with no instances and Karpenter adds them on demand
# (see ENABLE_AUTOSCALING). The configured counts are ignored.
if [ "${ENABLE_AUTOSCALING}" == "true" ]; then
  echo "ENABLE_AUTOSCALING=true: starting worker-group-1 and worker-group-2 with 0 instances"
  ACCEL_COUNT=0
  GEN_COUNT=0
fi

# Start writing the JSON
cat > hyperpod-config.json << EOL
{
    "ClusterName": "${HYPERPOD_NAME}",
    "Orchestrator": { 
      "Eks": 
      {
        "ClusterArn": "${EKS_CLUSTER_ARN}"
      }
    },
    "InstanceGroups": [
      {
        "InstanceGroupName": "worker-group-1",
        "InstanceType": "${ACCEL_INSTANCE_TYPE}",
        "InstanceCount": ${ACCEL_COUNT},
        "InstanceStorageConfigs": [
          {
            "EbsVolumeConfig": {
              "VolumeSizeInGB": ${ACCEL_VOLUME_SIZE}
            }
          }
        ],
        "LifeCycleConfig": {
          "SourceS3Uri": "s3://${S3_BUCKET_NAME}",
          "OnCreate": "on_create.sh"
        },
        "ExecutionRole": "${EXECUTION_ROLE}",
        "ThreadsPerCore": 1
EOL

# Conditionally add OnStartDeepHealthChecks only if not empty
if [ -n "${ONSTART_DEEP_HEALTHCHECKS}" ]; then
  echo '        ,"OnStartDeepHealthChecks": '${ONSTART_DEEP_HEALTHCHECKS} >> hyperpod-config.json
fi

# Finish writing the JSON
cat >> hyperpod-config.json << EOL
      },
      {
        "InstanceGroupName": "worker-group-2",
        "InstanceType": "${GEN_INSTANCE_TYPE}",
        "InstanceCount": ${GEN_COUNT},
        "InstanceStorageConfigs": [
          {
            "EbsVolumeConfig": {
              "VolumeSizeInGB": ${GEN_VOLUME_SIZE}
            }
          }
        ],
        "LifeCycleConfig": {
          "SourceS3Uri": "s3://${S3_BUCKET_NAME}",
          "OnCreate": "on_create.sh"
        },
        "ExecutionRole": "${EXECUTION_ROLE}",
        "ThreadsPerCore": 1
      }
EOL

cat >> hyperpod-config.json << EOL
    ],
    "VpcConfig": {
      "SecurityGroupIds": ["$SECURITY_GROUP_ID"],
      "Subnets":["$PRIVATE_SUBNET_ID"]
    },
    "NodeRecovery": "${NODE_RECOVERY}"
EOL
# Conditionally enable autoscaling with Karpenter. It needs continuous node provisioning.
if [ "${ENABLE_AUTOSCALING}" == "true" ]; then
cat >> hyperpod-config.json << EOL
    ,"NodeProvisioningMode": "Continuous",
    "ClusterRole": "${EXECUTION_ROLE}",
    "AutoScaling": {
      "Mode": "Enable",
      "AutoScalerType": "Karpenter"
    }
EOL
fi
echo "}" >> hyperpod-config.json

# Display the generated JSON file
echo "==== Generated hyperpod-config.json ===="
cat hyperpod-config.json
echo "=================================================="

# Validate the JSON if jq is available
if command -v jq &> /dev/null; then
    echo "==== Validate output JSON ===="
    if jq empty hyperpod-config.json 2>/dev/null; then
        echo "JSON is valid"
    else
        echo "ERROR: Invalid JSON"
        jq empty hyperpod-config.json
    fi
    echo "=================================="
fi
