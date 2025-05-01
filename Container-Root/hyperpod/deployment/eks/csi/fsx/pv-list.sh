#!/bin/bash

echo ""
echo "Listing Persistent Volumes (PV) ..."

CMD="kubectl get pv"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "${CMD}"

