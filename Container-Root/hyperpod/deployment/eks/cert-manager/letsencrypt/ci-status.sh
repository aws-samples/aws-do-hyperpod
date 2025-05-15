#!/bin/bash

# ClusterIssuer description

CMD="kubectl describe clusterissuer letsencrypt-production"
if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

echo ""

