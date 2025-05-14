#!/bin/bash

# Show certificate

usage(){
	echo ""
	echo "Usage: $0 <certificate_name>"
	echo ""
	echo "certificate_name   - name of certificate to show"
	echo ""
}

if [ "$1" == "" ]; then
	usage
else
	export CERTIFICATE_NAME=$1
	CMD="kubectl get certificate ${CERTIFICATE_NAME} | grep -v NAME | awk '{print \$3}'"
	if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
	export SECRET_NAME=$(eval "$CMD")

	CMD="cmctl inspect secret ${SECRET_NAME}"
	if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
        eval "$CMD"
fi

echo ""

