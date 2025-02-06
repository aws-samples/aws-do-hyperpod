#!/bin/bash

help(){
	echo ""
	echo "Usage: $0 <node_name> [metadata_name]"
	echo "       node_name     - required, partial or full node name of which to retrieve metadata"
	echo "       metadata_name - optional, name of metadata to retrieve"
        echo "                       if not specified, metadata options are listed"
	echo ""
}

if [ "$1" == "" ]; then
	help
else

	node_name=$1
        metadata_name=$2

	CMD="TOKEN=\$(curl -X PUT \\\"http://169.254.169.254/latest/api/token\\\" -H \\\"X-aws-ec2-metadata-token-ttl-seconds: 21600\\\"); echo \\\"\\\"; curl -H \\\"X-aws-ec2-metadata-token: \$TOKEN\\\" http://169.254.169.254/latest/meta-data/$metadata_name; echo \\\"\\\"; echo \\\"\\\""

	node-exec.sh $node_name "$CMD"

fi

