FROM docker.io/library/debian:stable-slim

# Maintainer and image description
LABEL maintainer="Arnulf Heimsbakk <arnulf.heimsbakk@gmail.com>"
LABEL description="Hugo runtime container"

RUN apt-get update; \
    apt-get install -y \
      curl \
      git \
      ; \
    apt-get clean

WORKDIR /work
