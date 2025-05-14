#!/bin/bash

# Trace domain resolution

usage(){
	echo ""
	echo "Usage: $0 <DOMAIN_NAME>"
	echo ""
	echo "DOMAIN_NAME   - FQDN of the domain to trace"
	echo ""
}

if [ "$1" == "" ]; then
	usage
else
	export DOMAIN_NAME=$1
	CMD="dig $DOMAIN_NAME ns +trace +nodnssec"
	if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
	eval "$CMD"
fi

echo ""

