#!/bin/bash

# Delete HyperPod Cluster
if [ ! "$1" == "" ]; then HYPERPOD_NAME=$1; fi

echo ""
echo "Deleting HyperPod cluster: $HYPERPOD_NAME"
echo ""
read -r -p "Are you sure? [y/N] " response
case "$response" in 
    [yY][eE][sS]|[yY])
        ./hyperpod-status.sh ${HYPERPOD_NAME}
        if [ "$?" == "0" ]; then
            CMD="aws sagemaker delete-cluster --cluster-name ${HYPERPOD_NAME} ${ENDPOINT_ARG}"
            if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
            eval "$CMD"
        else
            echo "HyperPod cluster $HYPERPOD_NAME does not exist"
        fi

        if [ "$DELETE_ALL" == "true" ]; then

            # Delete Kubernetes resources
            echo ""
            echo "Deleting Kubernetes resources"
            CMD="kubectl delete -f ${ENV_HOME}impl/eks/src/manifests"
            if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
            eval "$CMD"

            # Delete non-empty bucket
            echo ""
            echo "Deleting S3 bucket: $BUCKET_NAME"
            CMD="aws s3 rb --force s3://${BUCKET_NAME} --region $AWS_REGION"
            if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
            eval "$CMD"

            # Delete CloudFormation stack
            echo ""
            echo "Deleting CloudFormation stack: $STACK_ID"
            echo ""
            CMD="aws cloudformation delete-stack --stack-name $STACK_ID --region $AWS_REGION"
            if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
            eval "$CMD"
            echo ""
            echo "Waiting for stack deletion to complete ..."
            CMD="aws cloudformation wait stack-delete-complete --stack-name $STACK_ID"
            if [ ! "$VERBOSE" == "false" ]; then echo -e "\n${CMD}\n"; fi
            eval "$CMD"

        fi
        ;;
    *)
        echo ""
        echo "Cluster deletion cancelled"
        echo ""
        ;;
esac


