This directory represents the second phase of the Infrastructure as Code (IaC) evolution. The goal is to separate the application, database, and cache into isolated environments to simulate a production-grade distributed system.

## Architecture & Stack

Instead of one server, we now manage a three-node cluster connected via a private network:

- **Web Tier (`web-server`):** Nginx reverse proxy and Node.js application.

- **Database Tier (`db-server`):** PostgreSQL 18 server.

- **Cache Tier (`cache-server`):** Redis server.

## Features

- **Declarative Orchestration:** Entire stack configuration is defined in `site.yml` and broken down into reusable **Ansible Roles**.

- **Isolated Environments:** Each service runs on its own Virtual Machine with a dedicated private IP (192.168.56.x range).

- **Security (UFW):** A "Default Deny" firewall policy is implemented on all nodes, with explicit rules to allow cross-node communication on ports `5432` (Postgres) and `6379` (Redis).
- **Automated Service Discovery:** The Node.js application is injected with remote database and cache addresses at runtime via Ansible environment variables.
- **Optimized Execution:** SSH Pipelining and world-readable temporary files are enabled in `ansible.cfg` for faster, smoother provisioning of unprivileged users.

## How to Run Locally

This level continues to use **Vagrant** with the **KVM/libvirt** hypervisor but introduces **Ansible** as the primary provisioner.

1. **Provision the Hardware:**
   Boot the three-node cluster:

```bash
vagrant up --provider=libvirt

```

2. **Execute the Orchestration:**
   Run the master playbook from your host machine to configure all tiers:

```bash
ansible-playbook site.yml

```

3. **Verify Connectivity:**
   View the live application and its connection status to the remote backend:

- **App Root:** `http://192.168.56.12/`
- **Health Check:** `http://192.168.56.12/health` (Should return `true` for both Postgres and Redis).
