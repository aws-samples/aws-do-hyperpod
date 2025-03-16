#!/bin/bash

CMD="aws efs describe-file-systems --query 'FileSystems[*].{FileSystemId:FileSystemId,CreationTime:CreationTime,NumberOfMountTargets:NumberOfMountTargets,Tags:Tags}' --output table"

if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi

eval "$CMD"

