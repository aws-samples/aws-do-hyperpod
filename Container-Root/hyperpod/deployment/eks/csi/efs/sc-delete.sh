#!/bin/bash

usage(){
	echo ""
	echo "Usage: ${0} <efs_file_system_id>"
	echo ""
	echo "efs_file_system_id   - ID of the EFS file system used by the storage class to delete."
	echo ""
}

if [ "$1" == "" ]; then
	usage
else
        echo ""
        export FILE_SYSTEM_ID=$(aws efs describe-file-systems --file-system-id $1 --query 'FileSystems[].FileSystemId' --output text)
        if [ "$FILE_SYSTEM_ID" == "" ]; then
                echo "File system $1 not found."
        else
		cat ./efs-sc.yaml-template | envsubst > efs-sc-${FILE_SYSTEM_ID}.yaml
		cat efs-sc-${FILE_SYSTEM_ID}.yaml
		kubectl delete -f ./efs-sc-${FILE_SYSTEM_ID}.yaml
	fi
fi
