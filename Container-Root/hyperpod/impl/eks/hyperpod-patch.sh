#!/bin/bash

# Patch HyperPod Cluster
if [ ! "$1" == "" ]; then HYPERPOD_NAME=$1; fi

echo ""
echo "Patching HyperPod cluster: $HYPERPOD_NAME"
echo ""
read -r -p "Are you sure? [y/N] " response
case "$response" in 
    [yY][eE][sS]|[yY])
        ./hyperpod-status.sh ${HYPERPOD_NAME}
        if [ "$?" == "0" ]; then
            CMD="aws sagemaker update-cluster-software --cluster-name ${HYPERPOD_NAME} ${ENDPOINT_ARG}"
            if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
            eval "$CMD"
        else
            echo "HyperPod cluster $HYPERPOD_NAME does not exist"
        fi
        ;;
    *)
        echo ""
        echo "Cluster patching cancelled"
        echo ""
        ;;
esac


