#!/bin/bash

# Show status of certificate

CMD="kubectl logs -f deployment/letsencrypt-curl"
if [ ! "$verbose" == "false" ]; then echo -e "\n${CMD}\n"; fi
eval "$CMD"

echo ""

