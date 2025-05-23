#!/bin/bash

# Create hosted zone record

usage(){
	echo ""
	echo "Usage: $0 <FQDN> <TYPE> <VALUE>"
	echo ""
	echo "FQDN   - DNS name for the record to create"
	echo "TYPE   - record type: A | CNAME | NS"
	echo "VALUE  - record value specifying where this record is pointing to"
	echo ""
}

if [ "$3" == "" ]; then
	usage
else
        # Remove last character of FQDN if it is a dot
        export FQDN=$(echo $1 | sed -e 's/\.$//g')
	export DOMAIN_NAME=$(echo $FQDN | cut -d '.' -f 2-)
	export ACTION=CREATE
        export TYPE=$2
	export VALUE=$3

	CMD="verbose=false ./domain-id.sh ${DOMAIN_NAME}"
	if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
	export DOMAIN_ID=$(eval "$CMD")
	echo "DOMAIN_ID=$DOMAIN_ID"

	cat record.json-template | envsubst > record.json

	CMD="aws route53 change-resource-record-sets --hosted-zone-id ${DOMAIN_ID} --change-batch file://record.json"
	if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
	eval "$CMD"
fi
