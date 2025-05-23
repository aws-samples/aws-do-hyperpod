#!/bin/bash

# Show hosted zone id for a given domain name

usage(){
	echo ""
	echo "Usage: $0 <DOMAIN_NAME>"
	echo ""
	echo "DOMAIN_NAME   - FQDN of the domain to id"
	echo ""
}

if [ "$1" == "" ]; then
	usage
else
	export DOMAIN_NAME=$1
	CMD="aws route53 list-hosted-zones --query \"HostedZones[?Name=='${DOMAIN_NAME}.'].Id\" | jq -r .[]"
	if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
	eval "$CMD"
fi
