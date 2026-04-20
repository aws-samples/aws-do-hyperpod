#!/bin/bash

# Source: https://github.com/stern/stern
# Note: depends on install-krew.sh

export PATH=$PATH:${HOME}/.krew/bin

kubectl krew install stern

