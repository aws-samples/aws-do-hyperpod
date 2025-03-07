#!/bin/bash

usage(){
	echo ""
	echo "Usage: ${0} <efs_file_system_id>"
	echo ""
	echo "efs_file_system_id  - ID of EFS file system to delete"
        echo ""
}

if [ "$1" == "" ]; then
	usage
else
	echo ""
	FILE_SYSTEM_ID=$(aws efs describe-file-systems --file-system-id $1 --query 'FileSystems[].FileSystemId' --output text)
	if [ "$FILE_SYSTEM_ID" == "" ]; then
		echo "File system $1 not found."
	else
		echo "Deleting EFS mount targets for file system $FILE_SYSTEM_ID ..."
		MOUNT_TARGETS="$(aws efs describe-mount-targets --file-system-id $FILE_SYSTEM_ID --query MountTargets[].MountTargetId --output text)"
        	MT=$(echo $MOUNT_TARGETS)
        	for t in $MT; do echo Deleting mount target $t; aws efs delete-mount-target --mount-target-id $t; done 
		
		# Wait for mount targets to finish deleting
		MOUNT_TARGETS="$(aws efs describe-mount-targets --file-system-id $FILE_SYSTEM_ID --query MountTargets[].MountTargetId --output text)"
		while [ ! "$MOUNT_TARGETS" == "" ]; do
        		sleep 5
			MOUNT_TARGETS="$(aws efs describe-mount-targets --file-system-id $FILE_SYSTEM_ID --query MountTargets[].MountTargetId --output text)"
		done

		echo ""
        	echo "Deleting EFS file system $FILE_SYSTEM_ID ..."
        	CMD="aws efs delete-file-system --file-system-id $FILE_SYSTEM_ID"
		if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
		eval "$CMD"

		FSID=$(aws efs describe-file-systems --file-system-id $FILE_SYSTEM_ID --query 'FileSystems[].FileSystemId' --output text)
		while [ ! "$FSID" == "" ]; do
			sleep 3
			FSID=$(aws efs describe-file-systems --file-system-id $FILE_SYSTEM_ID --query 'FileSystems[].FileSystemId' --output text)
		done
		echo ""
		echo "FILE_SYSTEM_ID $FILE_SYSTEM_ID deleted."
	fi
fi

