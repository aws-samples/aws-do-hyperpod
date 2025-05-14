#!/bin/bash

# Deploy test app for specified certificate

usage(){
	echo ""
	echo "Usage: $0 <certificate_name>"
	echo ""
	echo "certificate_name   - name of certificate to deploy test app for"
	echo ""
}

if [ "$1" == "" ]; then
	usage
else
	export CERTIFICATE_NAME=$1
	CMD="kubectl get certificate ${CERTIFICATE_NAME} | grep -v NAME | awk '{print \$3}'"
	if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
	export SECRET_NAME=$(eval "$CMD")

	CMD="envsubst < selfsigned-app.yaml-template > ./selfsigned-app.yaml && kubectl apply -f ./selfsigned-app.yaml"
	if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
	eval "$CMD"
fi
