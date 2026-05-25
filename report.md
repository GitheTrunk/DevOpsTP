# TP5 — Automated Laravel Deployment with Ansible and Docker

## Overview

Exercise: Automate deployment of two Laravel environments (staging and production) using Ansible. The setup uses Docker on macOS with an Ansible control container and an Ubuntu-based managed node running Nginx, PHP-FPM and MariaDB.

## Environment

- Control node: Ansible container (`ansible-mac`)
- Managed node: Ubuntu container (`child-node`)
- Web server: Nginx
- Framework: Laravel
- Deployment targets: Staging and Production

---

## Objectives

- Configure a remote (managed) machine
- Install and validate required packages and services
- Configure Nginx and virtual hosts for two Laravel sites
- Deploy application code for staging and production
- Configure environment variables and databases
- Install Composer and NPM dependencies and build frontend assets
- Verify services and final deployment

---

## System Architecture
```
MacOS host
├─ Docker network: `ansible-net`
├─ Control container: `ansible-mac` (runs Ansible)
└─ Managed container: `child-node` (runs Nginx, PHP-FPM, MariaDB, Laravel sites)

Communication: Ansible control node → SSH → child node
```
---

## Setup Steps (summary)

1. Create Docker network:

  docker network create ansible-net

2. Start managed node:

  docker run -d --name child-node --network ansible-net ubuntu:24.04 sleep infinity

3. Configure SSH inside managed node:

  - install `openssh-server`, `python3`, `sudo`
  - create `/run/sshd`, enable `PasswordAuthentication` and `PermitRootLogin` (for lab), start `sshd`

4. Start Ansible control container:

  docker run -it --network ansible-net -v $(pwd):/workspace -v ~/.ssh:/root/.ssh ansible-mac

5. Inventory (`inventory.ini`):

  [laravel]
  child-node ansible_host=child-node

  [laravel:vars]
  ansible_user=root

6. Verify connectivity:

  - SSH: `ssh root@child-node`
  - Ansible ping: `ansible laravel -i inventory.ini -m ping -k` (expect `pong`)

---

## Playbook Tasks

- Install packages: `nginx`, `git`, `composer`, `npm`, `mariadb-server`, `php8.3-fpm` and PHP extensions (`mysql`, `xml`, `mbstring`, `curl`, `zip`)
- Ensure services are running: `nginx`, `mariadb`, `php8.3-fpm`
- Create directories:
  - `/var/www/html/staging`
  - `/var/www/html/production`
  Set ownership to `www-data:www-data`.
- Deploy application from Git: https://github.com/taltongsreng/i4gic2024.git into both site directories
- Generate environment files (`.env`) for staging and production with respective DB names
- Run `composer install` for PHP dependencies
- Fix NPM permissions (`/var/www/.npm`) and run `npm install` and `npm run build`
- Generate Laravel app key: `php artisan key:generate`
- Configure Nginx virtual hosts pointing to each site's `/public` folder, test (`nginx -t`) and restart Nginx

---

## Deployment Example Commands

ansible-playbook -i inventory.ini deploy.yml -k

After a successful run the play recap indicated zero failures.

---

## Validation

- Confirm site directories exist: `ls /var/www/html` → `staging`, `production`
- Validate Nginx: `nginx -t` → `syntax is ok` and `test is successful`

---

## Issues and Notes

- SSH timeouts: resolved by creating a shared Docker network
- `Permission denied (publickey)`: adjusted SSH configuration and enabled password auth for lab
- Host key verification: added fingerprints to `known_hosts`
- NPM EACCES errors: fixed by setting `/var/www/.npm` ownership to `www-data`
- SMTP/email connection refused: no mail server in the container; handled or ignored in playbook where applicable

---

## Results

All required tasks completed successfully: Docker networking, SSH configuration, Ansible automation, Nginx, PHP, MariaDB, Composer and NPM installs, and deployments for both staging and production. Deployment status: SUCCESS.

---

## Conclusion

This exercise demonstrates automated infrastructure deployment using Ansible and Docker, showing how to provision services, deploy Laravel applications, manage environment configuration, and validate the resulting web stack.

### Technologies used

- Docker
- Ubuntu
- SSH
- Ansible
- Nginx
- PHP (PHP-FPM)
- Composer
- MariaDB
- Laravel
