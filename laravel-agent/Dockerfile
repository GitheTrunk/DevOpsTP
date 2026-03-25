FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install system packages
RUN apt update && apt install -y \
    openssh-client \
    curl \
    git \
    unzip \
    python3 \
    python3-pip \
    nodejs \
    npm \
    openjdk-17-jdk \
    php \
    php-cli \
    php-mbstring \
    php-xml \
    php-bcmath \
    php-curl \
    php-mysql \
    && apt clean

# Install Ansible
RUN pip3 install ansible

# Set workspace
WORKDIR /workspace

# Keep container running
CMD ["sleep", "infinity"]