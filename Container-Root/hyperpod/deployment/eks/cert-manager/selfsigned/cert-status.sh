#!/bin/bash

# Show status of certificate

usage(){
	echo ""
	echo "Usage: $0 <certificate_name>"
	echo ""
	echo "certificate_name   - name of certificate to provide status for"
	echo ""
}

if [ "$1" == "" ]; then
	usage
else
	export CERTIFICATE_NAME=$1
	CMD="cmctl status certificate ${CERTIFICATE_NAME}"
	if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
	eval "$CMD"
fi

echo ""

