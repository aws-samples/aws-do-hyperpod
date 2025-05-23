#!/bin/bash

# List certificates

usage() {
	echo ""
	echo "Usage: $0 [DNS_NAME]"
	echo ""
	echo "DNS_NAME   - optional, list certificates for the specified DNS name only"
	echo ""
}

if [ "$1" == "--help" ]; then
	usage
else

	if [ "$1" == "" ]; then
		CMD="kubectl get certificate"
	else
		CERT_NAME=$(echo $1 | sed -e 's/\./-/g')
		CMD="kubectl get certificate | grep ${CERT_NAME}"
	fi
	if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
	eval "$CMD"
fi

echo ""

