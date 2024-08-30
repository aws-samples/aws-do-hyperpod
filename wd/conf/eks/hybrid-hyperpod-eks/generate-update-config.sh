#!/bin/bash

source ./env_input
source ./env_vars

cat > hyperpod-update-config.json << EOL
{
    "ClusterName": "${HYPERPOD_NAME}",
    "InstanceGroups": [
      {
        "InstanceGroupName": "worker-group-1",
        "InstanceType": "${ACCEL_INSTANCE_TYPE1}",
        "InstanceCount": ${ACCEL_COUNT1},
        "LifeCycleConfig": {
          "SourceS3Uri": "s3://${BUCKET_NAME}",
          "OnCreate": "on_create.sh"
        },
        "ExecutionRole": "${EXECUTION_ROLE}",
        "ThreadsPerCore": 1,
        "EnableBurnInTest": ${BURN_ENABLED}
      },
      {
        "InstanceGroupName": "worker-group-2",
        "InstanceType": "${GEN_INSTANCE_TYPE}",
        "InstanceCount": ${GEN_COUNT},
        "LifeCycleConfig": {
          "SourceS3Uri": "s3://${BUCKET_NAME}",
          "OnCreate": "on_create.sh"
        },
        "ExecutionRole": "${EXECUTION_ROLE}",
        "ThreadsPerCore": 1
      },
      {
        "InstanceGroupName": "worker-group-3",
        "InstanceType": "${ACCEL_INSTANCE_TYPE2}",
        "InstanceCount": ${ACCEL_COUNT2},
        "LifeCycleConfig": {
          "SourceS3Uri": "s3://${BUCKET_NAME}",
          "OnCreate": "on_create.sh"
        },
        "ExecutionRole": "${EXECUTION_ROLE}",
        "ThreadsPerCore": 1,
        "EnableBurnInTest": ${BURN_ENABLED}
      },
      {
        "InstanceGroupName": "worker-group-4",
        "InstanceType": "${ACCEL_INSTANCE_TYPE3}",
        "InstanceCount": ${ACCEL_COUNT3},
        "LifeCycleConfig": {
          "SourceS3Uri": "s3://${BUCKET_NAME}",
          "OnCreate": "on_create.sh"
        },
        "ExecutionRole": "${EXECUTION_ROLE}",
        "ThreadsPerCore": 1,
        "EnableBurnInTest": ${BURN_ENABLED}
      }
    ],
    "ResilienceConfig": {
      "EnableNodeAutoRecovery": ${RECOVER_ENABLED}
    }
}
EOL
