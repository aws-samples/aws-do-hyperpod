#!/bin/bash

######################################################################
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. #
# SPDX-License-Identifier: MIT-0                                     #
######################################################################

# Helper functions
## Detect current operating system
function os
{
        UNAME=$(uname -a)
        if [ $(echo $UNAME | awk '{print $1}') == "Darwin" ]; then
                export OPERATING_SYSTEM="MacOS"
        elif [ $(echo $UNAME | awk '{print $1}') == "Linux" ]; then
                export OPERATING_SYSTEM="Linux"
        elif [ ${UNAME:0:5} == "MINGW" ]; then
                export OPERATING_SYSTEM="Windows"
                export MSYS_NO_PATHCONV=1 # turn off path conversion
        else
                export OPERATING_SYSTEM="Other"
        fi
}
## End os function
os

