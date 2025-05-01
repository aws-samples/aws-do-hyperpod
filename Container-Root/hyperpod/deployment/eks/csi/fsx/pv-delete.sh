#!/bin/bash

echo ""
echo "Deleting Persistent Volume (fsx-pv) ..."

CMD="kubectl delete pv fsx-pv"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "${CMD}"

