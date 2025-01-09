#!/bin/bash

echo ""
echo "Describing FSxL volumes ..."

CMD="aws fsx describe-file-systems"
if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "${CMD}"

