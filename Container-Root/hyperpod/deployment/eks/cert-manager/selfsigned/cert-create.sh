#!/bin/bash

# Create self-signed certificate

usage(){
	echo ""
	echo "Usage: $0 <FQDN>"
	echo ""
	echo "FQDN   - fully-qualified domain name to protect with certificate"
	echo ""
}

if [ "$1" == "" ]; then
	usage
else
	export FQDN=$1
	export CERTIFICATE_NAME=$(echo ${FQDN} | sed -e 's/\./-/g')
	CMD="envsubst < certificate.yaml-template > ./certificate.yaml && cat ./certificate.yaml && echo '' && kubectl apply -f ./certificate.yaml"
	if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
	eval "$CMD"
fi

echo ""

