#!/bin/bash

# List hosted zones

CMD="aws route53 list-hosted-zones --query HostedZones[].Name | jq -r .[] | sed 's/.$//' | sort"
if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

echo ""

