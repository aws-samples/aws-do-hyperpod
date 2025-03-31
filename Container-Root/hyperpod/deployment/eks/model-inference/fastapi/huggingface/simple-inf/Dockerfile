ARG BASE_IMAGE_PATH="alpine:latest"

FROM $BASE_IMAGE_PATH

ARG BUILD="202104"
ARG MAINTAINER="Full Name <email@company.com>"
ARG DESCRIPTION="Depend on Docker Image"
ARG http_proxy
ARG https_proxy
ARG no_proxy

LABEL MAINTAINER="$MAINTAINER"

LABEL DESCRIPTION="$DESCRIPTION"

LABEL BUILD="$BUILD"

ADD Container-Root /

RUN export http_proxy=$http_proxy; export https_proxy=$https_proxy; export no_proxy=$no_proxy; /setup.sh; rm -f /setup.sh

WORKDIR /

CMD /startup.sh

