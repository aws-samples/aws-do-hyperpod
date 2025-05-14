#!/bin/bash

# Create hosted zone

usage(){
	echo ""
	echo "Usage: $0 <DOMAIN_NAME>"
	echo ""
	echo "DOMAIN_NAME   - FQDN of hosted zone to create"
	echo ""
}

if [ "$1" == "" ]; then
	usage
else
	export DOMAIN_NAME=$1
	CMD="aws route53 create-hosted-zone --caller-reference $(uuidgen) --name $DOMAIN_NAME"
	if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
	eval "$CMD"
fi

