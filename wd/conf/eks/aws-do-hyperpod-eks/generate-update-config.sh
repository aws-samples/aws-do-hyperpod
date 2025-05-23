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

# Start writing the JSON
cat > hyperpod-update-config.json << EOL
{
    "ClusterName": "${HYPERPOD_NAME}",
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
  echo '        ,"OnStartDeepHealthChecks": '${ONSTART_DEEP_HEALTHCHECKS} >> hyperpod-update-config.json
fi

cat >> hyperpod-update-config.json << EOL
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
    ],
    "NodeRecovery": "${NODE_RECOVERY}"
}
EOL

# Display the generated JSON file
echo "==== Generated hyperpod-update-config.json ===="
cat hyperpod-update-config.json
echo "=================================================="

# Validate the JSON if jq is available
if command -v jq &> /dev/null; then
    echo "==== Validate output JSON ===="
    if jq empty hyperpod-update-config.json 2>/dev/null; then
        echo "JSON is valid"
    else
        echo "ERROR: Invalid JSON"
        jq empty hyperpod-update-config.json
    fi
    echo "=================================="
fi