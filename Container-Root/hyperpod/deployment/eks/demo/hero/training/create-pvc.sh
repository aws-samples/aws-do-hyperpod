#!/bin/bash

# Set target namespace
TARGET_NAMESPACE="hyperpod-ns-training-team"



# Get FSx filesystem information
if [ -z "$FSX_ID" ]; then
    echo "FSX_ID not set. Attempting to find an available FSx filesystem..."
    FSX_ID=$(aws fsx describe-file-systems --region ${AWS_REGION} | jq -r '.FileSystems[0].FileSystemId')
    if [ -z "$FSX_ID" ]; then
        echo "Error: Could not find any FSx filesystem"
        exit 1
    else
        echo "Using FSx filesystem: $FSX_ID"
    fi
else
    echo "Using provided FSX_ID: $FSX_ID"
    # Verify if the provided FSX_ID exists
    if ! aws fsx describe-file-systems --file-system-id $FSX_ID --region ${AWS_REGION} &> /dev/null; then
        echo "Error: Provided FSX_ID $FSX_ID does not exist or is not accessible"
        exit 1
    fi
fi

# Get Private Subnet ID
PRIVATE_SUBNET_ID=$(aws fsx describe-file-systems --file-system-id ${FSX_ID} --region ${AWS_REGION} --query 'FileSystems[0].SubnetIds[0]' --output text)

# Get the security group
CLUSTER_INFO=$(aws sagemaker describe-cluster --cluster-name hero-cluster)
SECURITY_GROUP=$(echo "$CLUSTER_INFO" | jq -r '.VpcConfig.SecurityGroupIds[0]')

# Get FSx DNS name
FSX_DNS=$(aws fsx describe-file-systems --region ${AWS_REGION} --file-system-id ${FSX_ID} --query 'FileSystems[0].DNSName' --output text)

# Get FSx Mount name
FSX_MOUNT=$(aws fsx describe-file-systems --region ${AWS_REGION} --file-system-id ${FSX_ID} --query 'FileSystems[0].LustreConfiguration.MountName' --output text)

# Create StorageClass
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fsx-sc-${TARGET_NAMESPACE}
provisioner: fsx.csi.aws.com
parameters:
  fileSystemId: ${FSX_ID}
  subnetId: ${PRIVATE_SUBNET_ID}
  securityGroupIds: ${SECURITY_GROUP}
EOF

# Create PersistentVolume
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: fsx-pv-${TARGET_NAMESPACE}
spec:
  capacity:
    storage: 1200Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: fsx-sc-${TARGET_NAMESPACE}
  csi:
    driver: fsx.csi.aws.com
    volumeHandle: ${FSX_ID}
    volumeAttributes:
      dnsname: ${FSX_DNS}
      mountname: ${FSX_MOUNT}
EOF

# Create PersistentVolumeClaim in the target namespace
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: fsx-claim
  namespace: ${TARGET_NAMESPACE}
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: fsx-sc-${TARGET_NAMESPACE}
  resources:
    requests:
      storage: 1200Gi
EOF


# Verify the resources
echo -e "\nVerifying created resources:"
echo "StorageClass:"
kubectl get sc fsx-sc-${TARGET_NAMESPACE}
echo -e "\nPersistentVolume:"
kubectl get pv fsx-pv-${TARGET_NAMESPACE}
echo -e "\nPersistentVolumeClaim:"
kubectl get pvc -n ${TARGET_NAMESPACE} fsx-claim
