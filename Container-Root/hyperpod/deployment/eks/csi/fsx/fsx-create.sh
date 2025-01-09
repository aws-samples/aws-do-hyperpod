#!/bin/bash

# Config
export STORAGE_CAPACITY=43200

if [ ! "$SUBNET_ID" == "" ]; then
	if [ ! "$SECURITY_GROUP_ID" == "" ]; then
		echo ""
		echo "Creating FSxL volume with capacity $STORAGE_CAPACITY and EFA enabled ..."

		CMD="aws fsx create-file-system --storage-capacity $STORAGE_CAPACITY --storage-type SSD --file-system-type LUSTRE --subnet-ids $SUBNET_ID --security-group-ids $SECURITY_GROUP_ID --lustre-configuration 'DeploymentType=PERSISTENT_2,PerUnitStorageThroughput=1000,EfaEnabled=true,MetadataConfiguration={Mode=AUTOMATIC}'"
		if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
		FILE_SYSTEM_RESPONSE=$(eval "${CMD}")
		echo "$FILE_SYSTEM_RESPONSE"
		export FILE_SYSTEM_ID=$(echo $FILE_SYSTEM_RESPONSE | jq -r .FileSystem.FileSystemId)
		echo ""
		echo "FILE_SYSTEM_ID=$FILE_SYSTEM_ID"
	else
		echo "SECURITY_GROUP_ID is required"
	fi
else
	echo "SUBNET_ID is required"
fi


