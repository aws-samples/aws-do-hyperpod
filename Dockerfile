FROM public.ecr.aws/ubuntu/ubuntu:22.04

ARG http_proxy
ARG https_proxy
ARG no_proxy
ARG MOD

ENV AWS_PAGER=""
ENV VERBOSE="true"
ENV DEBIAN_FRONTEND=noninteractive

RUN adduser --uid 1000 --gid 100 --shell /bin/bash sagemaker-user
RUN usermod -aG sudo sagemaker-user
RUN mkdir -p /etc/sudoers.d /aws-do-hyperpod
RUN echo "%sudo ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/nopasswd && chmod 0440 /etc/sudoers.d/nopasswd
RUN rm -f /hyperpod/conf

ADD Container-Root /

ADD wd/conf /hyperpod/conf

RUN export http_proxy=$http_proxy; export https_proxy=$https_proxy; export no_proxy=$no_proxy; export MOD=$MOD; /setup.sh; rm -f /setup.sh

RUN chown -R sagemaker-user:users /hyperpod /wd

RUN chown sagemaker-user:users /*.sh /*.txt

USER sagemaker-user

RUN /hyperpod/setup/eks/install-kubeps1.sh
RUN /hyperpod/setup/install-bashrc.sh

WORKDIR /aws-do-hyperpod

CMD /startup.sh

