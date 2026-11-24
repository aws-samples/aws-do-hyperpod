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
EOL

# Conditionally add the instance group that Karpenter scales (see ENABLE_AUTOSCALING).
# Karpenter changes the count of this group, so keep its current count if it already
# exists in the cluster. A new group starts with 0 nodes.
if [ "${ENABLE_AUTOSCALING}" == "true" ]; then
  REGION_OPT=""
  if [ -n "${AWS_REGION}" ]; then REGION_OPT="--region ${AWS_REGION}"; fi
  AUTOSCALE_COUNT=$(aws sagemaker describe-cluster --cluster-name ${HYPERPOD_NAME} --query "InstanceGroups[?InstanceGroupName=='${AUTOSCALE_GROUP_NAME}'].TargetCount | [0]" --output text ${REGION_OPT} ${ENDPOINT_ARG} 2>/dev/null)
  if ! [[ "${AUTOSCALE_COUNT}" =~ ^[0-9]+$ ]]; then
    AUTOSCALE_COUNT=0
  fi
  echo "Autoscaling instance group ${AUTOSCALE_GROUP_NAME} count: ${AUTOSCALE_COUNT}"
cat >> hyperpod-update-config.json << EOL
      ,{
        "InstanceGroupName": "${AUTOSCALE_GROUP_NAME}",
        "InstanceType": "${AUTOSCALE_INSTANCE_TYPE}",
        "InstanceCount": ${AUTOSCALE_COUNT},
        "InstanceStorageConfigs": [
          {
            "EbsVolumeConfig": {
              "VolumeSizeInGB": ${AUTOSCALE_VOLUME_SIZE}
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
fi

cat >> hyperpod-update-config.json << EOL
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