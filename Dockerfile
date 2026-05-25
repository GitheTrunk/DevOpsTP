FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y \
    ansible \
    openssh-client \
    git \
    sshpass \
    python3 \
    python3-pip \
    && apt clean

WORKDIR /workspace

CMD ["bash"]