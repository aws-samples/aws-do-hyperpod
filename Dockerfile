FROM public.ecr.aws/ubuntu/ubuntu:22.04

ARG http_proxy
ARG https_proxy
ARG no_proxy

ENV DEBIAN_FRONTEND=noninteractive
ENV AWS_PAGER=""
ENV VERBOSE="true"

ADD Container-Root /

RUN export http_proxy=$http_proxy; export https_proxy=$https_proxy; export no_proxy=$no_proxy; /setup.sh; rm -f /setup.sh

WORKDIR /hyperpod

CMD /startup.sh

