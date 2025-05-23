#!/bin/bash

echo ""
echo "Removing Run.ai control plane ..."
helm uninstall runai-backend -n runai-backend

echo ""
echo "Deleting Run.ai PVCs ..."
kubectl -n runai-backend delete pvc data-runai-backend-postgresql-0 data-runai-backend-redis-queue-master-0 data-runai-backend-thanos-receive-0

echo ""

