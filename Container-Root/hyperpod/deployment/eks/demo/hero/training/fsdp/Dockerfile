# FROM --platform=linux/amd64 public.ecr.aws/hpc-cloud/nccl-tests:cuda12.8.1-efa1.41.0-ofiv1.15.0-ncclv2.26.6-1-testsv2.15.2
FROM --platform=linux/amd64 public.ecr.aws/hpc-cloud/nccl-tests:efa1.38.1-ofiv1.14.0-ncclv2.26.2-1-testsv2.14.1



RUN apt update && apt install -y nvtop

RUN mkdir -p /fsdp /checkpoints
RUN ln -s /usr/bin/python3 /usr/bin/python

COPY src/ /fsdp/
RUN --mount=type=cache,target=/root/.cache/pip pip install -r /fsdp/requirements.txt
RUN pip install hyperpod-elastic-agent

WORKDIR /fsdp
