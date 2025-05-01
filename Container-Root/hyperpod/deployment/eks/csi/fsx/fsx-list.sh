#!/bin/bash

echo ""
echo "Listing FSxL volumes ..."

CMD="aws fsx describe-file-systems --query 'FileSystems[].{FileSystemId:FileSystemId,FileSystemType:FileSystemType,StorageCapacity:StorageCapacity,VpcId:VpcId,Lifecycle:Lifecycle}' --output table"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "${CMD}"

