#!/bin/bash

# Delete hosted zone

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
	echo ""
	echo "Deleting domain: $DOMAIN_NAME"
	echo ""
	read -r -p "Are you sure? [y/N] " response
	case "$response" in
    		[yY][eE][sS]|[yY])
			CMD="verbose=false ./domain-id.sh $DOMAIN_NAME"
			if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
			DOMAIN_ID=$(eval "$CMD")
			echo "DOMAIN_ID=$DOMAIN_ID"

			CMD="aws route53 delete-hosted-zone --id $DOMAIN_ID"
			if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
			eval "$CMD"
			;;
    		*)
        		echo ""
        		echo "Domain deletion cancelled"
        		echo ""
        		;;
	esac		
fi

