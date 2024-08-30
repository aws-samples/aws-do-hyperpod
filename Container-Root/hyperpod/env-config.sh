#!/bin/bash

source conf/env.conf

CMD="$EDITOR conf/env.conf"

if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi

eval "$CMD"

