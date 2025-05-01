#!/bin/bash

help() {
	echo ""
	echo "Usage: $0 <fsx_file_system_id>"
	echo ""
	echo "fsx_file_system_id   - id of the file system to use for creating a Kubernetes persistent volume"
	echo ""
}

if [ "$1" == "" ]; then
	help
else

echo ""
echo "Creating Persistent Volume (fsx-pv) for file system id $1 ..."

FS_PROPERTIES=$(aws fsx describe-file-systems --file-system-id $1 --query "FileSystems[].{StorageCapacity:StorageCapacity,DNSName:DNSName,MountName:LustreConfiguration.MountName}" --output json)

MOUNT_NAME=$(echo ${FS_PROPERTIES} | jq -r '.[].MountName')

DNS_NAME=$(echo ${FS_PROPERTIES} | jq -r '.[].DNSName')

STORAGE_CAPACITY=$(echo ${FS_PROPERTIES} | jq -r '.[].StorageCapacity')

cat <<EOF> fsx-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: fsx-pv
spec:
  capacity:
    storage: ${STORAGE_CAPACITY}Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  mountOptions:
    - flock
  persistentVolumeReclaimPolicy: Recycle
  csi:
    driver: fsx.csi.aws.com
    volumeHandle: $1
    volumeAttributes:
      dnsname: $DNS_NAME
      mountname: $MOUNT_NAME
EOF

CMD="kubectl apply -f ./fsx-pv.yaml"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "${CMD}"

