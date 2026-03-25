📄 TP3_setup.md
# TP3 - DevOps Pipeline (Jenkins + Ansible + Laravel + Telegram)

## Student Information
- Name: BUN Sengleang
- Project: TP3 DevOps Deployment

## Objective
Build a complete CI/CD pipeline using:
- Jenkins
- Docker (controller + agent)
- Ansible
- Laravel
- Telegram notifications

## Architecture

```text
Jenkins (Docker)
    |
    v
Agent (Docker with Ansible)
    |
    v
Remote Server (178.128.93.188)
    |
    v
Laravel Deployment (/var/www/BUN_Sengleang)
```

## Docker Setup

### docker-compose.yml
```yaml
services:
  jenkins:
    image: jenkins/jenkins:lts
    container_name: jenkins-devops
    privileged: true
    user: root
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - ./jenkins_home:/var/jenkins_home

  agent:
    build: ./laravel-agent
    container_name: laravel-agent
    tty: true
```

### Agent Dockerfile
```dockerfile
FROM ubuntu:22.04

RUN apt update && apt install -y \
    openssh-client \
    curl \
    git \
    unzip \
    python3 \
    python3-pip \
    nodejs \
    npm \
    php \
    php-cli \
    php-mbstring \
    php-xml \
    php-bcmath \
    php-curl \
    php-mysql

RUN pip3 install ansible

WORKDIR /workspace
```

## SSH Setup (Important)

### Problem
Ansible failed with:

```text
Permission denied (publickey,password)
```

### Solution
Generate key:
```bash
ssh-keygen -t ed25519
```

Copy key to server:
```bash
ssh-copy-id root@178.128.93.188
```

For Docker agent:
- Copy key into container, or
- Mount `.ssh` into the container

## Ansible Inventory

```ini
[web]
178.128.93.188 ansible_user=root ansible_ssh_private_key_file=/root/.ssh/id_ed25519
```

## Ansible Playbook

```yaml
- hosts: web
  become: yes

  vars:
    project_path: /var/www/BUN_Sengleang

  tasks:
    - name: Install packages
      apt:
        name:
          - git
          - curl
          - unzip
          - php
          - nodejs
          - npm
        update_cache: yes

    - name: Create Laravel project
      command: composer create-project laravel/laravel "{{ project_path }}"
      args:
        creates: "{{ project_path }}/artisan"

    - name: Generate key
      command: php artisan key:generate
      args:
        chdir: "{{ project_path }}"

    - name: Install npm
      command: npm install
      args:
        chdir: "{{ project_path }}"

    - name: Build frontend
      command: npm run build
      args:
        chdir: "{{ project_path }}"
```

## Jenkins Pipeline

```groovy
pipeline {
    agent { label 'laravel-agent' }

    stages {
        stage('Check connection') {
            steps {
                sh 'ansible -i /workspace/hosts.ini web -m ping'
            }
        }

        stage('Deploy Laravel') {
            steps {
                sh 'ansible-playbook -i /workspace/hosts.ini /workspace/deploy.yml'
            }
        }
    }

    post {
        success {
            sh '''
            curl -s -X POST https://api.telegram.org/bot<TOKEN>/sendMessage \
            -d chat_id=<CHAT_ID> \
            -d text="Deployment SUCCESS. Job: ${JOB_NAME} Build: #${BUILD_NUMBER}"
            '''
        }

        failure {
            sh '''
            curl -s -X POST https://api.telegram.org/bot<TOKEN>/sendMessage \
            -d chat_id=<CHAT_ID> \
            -d text="Deployment FAILED. Job: ${JOB_NAME} Build: #${BUILD_NUMBER}"
            '''
        }
    }
}
```

## Nginx Configuration

```nginx
server {
    listen 80;
    server_name sengleang.local;

    root /var/www/BUN_Sengleang/public;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
    }
}
```

## Errors Encountered and Solutions

1. SSH Permission Denied
   - Cause: No SSH key
   - Fix: `ssh-copy-id`

2. Ansible Module Error
   - Error: `No module named 'ansible.module_utils.six.moves'`
   - Cause: Broken Ansible installation
   - Fix: `pip3 install ansible`

3. Playbook Not Found
   - Error: `deploy.yml could not be found`
   - Cause: Wrong path
   - Fix: `/workspace/deploy.yml`

4. Jenkins Agent Offline
   - Cause: Java missing or connection issue
   - Fix: `apt install openjdk-17-jdk`

5. Laravel 500 Error (Database)
   - Error: `attempt to write a readonly database`
   - Fix: `chmod -R 775 database storage bootstrap/cache`

6. Nginx Conflict
   - Error: `conflicting server name`
   - Fix: Use a unique `server_name` or another port

## Telegram Integration

Get chat ID:
```text
https://api.telegram.org/bot<TOKEN>/getUpdates
```

Send message:
```bash
curl -X POST https://api.telegram.org/bot<TOKEN>/sendMessage \
  -d chat_id=YOUR_CHAT_ID \
  -d text="Hello from Jenkins"
```

## Final Result

- Jenkins pipeline working
- Ansible deployment working
- Laravel hosted on server
- Telegram notifications working

## Conclusion
This project demonstrates a complete DevOps pipeline with:
- Automated deployment using Ansible
- CI/CD orchestration using Jenkins
- Containerized tooling with Docker
- Real-time status notification via Telegram