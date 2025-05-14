#!/bin/bash

# List hosted zone records

usage(){
	echo ""
	echo "Usage: $0 <DOMAIN_NAME>"
	echo ""
	echo "DOMAIN_NAME   - FQDN of the domain to list records of"
	echo ""
}

if [ "$1" == "" ]; then
	usage
else
	export DOMAIN_NAME=$1
	#CMD="aws route53 list-hosted-zones --query \"HostedZones[?Name=='${DOMAIN_NAME}.'].Id\" | jq -r .[]"
	CMD="verbose=false ./domain-id.sh ${DOMAIN_NAME}"
	if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
	export DOMAIN_ID=$(eval "$CMD")
	echo "DOMAIN_ID=$DOMAIN_ID"

	CMD="aws route53 list-resource-record-sets --hosted-zone-id ${DOMAIN_ID} --query 'ResourceRecordSets[*].{Name: Name,Type: Type, Value: ResourceRecords[0].Value}' --output table"
	if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
	eval "$CMD"
fi
