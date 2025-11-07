#!/bin/bash

docker run --name=do-hyperpod-use1 \
  --hostname=deb706ea3971 \
  --mac-address=8a:15:14:f3:90:39 \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  --volume $(pwd):/hero-demo-hyperpod \
  --volume ~/.kube:/root/.kube \
  --volume ~/.aws:/root/.aws \
  --network=bridge \
  --workdir=/hyperpod \
  --detach=true \
  public.ecr.aws/hpc-cloud/aws-do-hyperpod:latest \
  tail -f /dev/null
