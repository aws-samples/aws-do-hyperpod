#!/bin/bash

echo ""
echo "Showing content of Run:ai FSX volumes ..."

echo ""
echo "Starting fsx-pod ..."
kubectl apply -f ./fsx-pod.yaml -n runai-backend

echo ""
# Wait for fsx-pod to start running
STATUS=$(kubectl get pods -n runai-backend| grep fsx-pod | awk '{print $3}')
while [ ! "$STATUS" == "Running" ]; do
    echo "Waiting for fsx-pod to start ..."
    sleep 3
    STATUS=$(kubectl get pods -n runai-backend | grep fsx-pod | awk '{print $3}')
done

echo ""
echo "Showing fsx volumes ..."
kubectl -n runai-backend exec -it fsx-pod -- bash -c 'echo "" && echo /fsx-postgres && ls -alh /fsx-postgres && echo "" && echo /fsx-redis && ls -alh /fsx-redis && echo "" && echo /fsx-thanos && ls -alh /fsx-thanos'

echo ""
echo "Removing fsx-pod ..."
kubectl delete -f ./fsx-pod.yaml -n runai-backend

echo ""
