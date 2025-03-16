#!/bin/bash

# Deploy EFS CSI and pod to current cluster

./csi-deploy.sh 

./efs-create.sh | tee efs-create.log

FILE_SYSTEM_ID=$(cat ./efs-create.log | tail -n 1)

./sc-create.sh $FILE_SYSTEM_ID

./pvc-create.sh

./pod-create.sh

kubectl get pod -A | grep efs-pod

