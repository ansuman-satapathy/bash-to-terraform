# The IaC Evolution: From Bash to Terraform

This repository demonstrates the evolution of Infrastructure as Code (IaC) and Configuration Management. It is structured as a 3-part journey, taking a raw Linux environment and progressively upgrading the deployment methodology to solve the limitations of the previous stage.

## 🎯 The Goal

To provision the infrastructure for a standard 3-tier web application (Web Server, Cache, and Database) using three entirely different DevOps philosophies.

**The Application Stack:**

- **Frontend/API:** A Node.js application (Express).
- **Cache:** Redis.
- **Database:** PostgreSQL.
- **Proxy:** Nginx.

---

## 🚀 The 3 Stages of Evolution

### [Level 1: The "Startup Monolith" (Bash)](./level-1-bash)

- **The Architecture:** All services running on a single Ubuntu 22.04 VM.
- **The Tooling:** A procedural Bash `bootstrap.sh` script.
- **The Lesson:** Demonstrates how to configure OS-level services (systemd, UFW, PM2) and integrate official GPG-secured package repositories. Exposes the fragility and lack of native idempotency inherent in imperative shell scripting.

### Level 2: Configuration Management (Ansible) - _Coming Soon_

- **The Architecture:** A distributed 3-node environment (Web Server, Redis Server, Postgres Server).
- **The Tooling:** Ansible Playbooks and Roles.
- **The Lesson:** Upgrades the infrastructure to a **declarative** state. Demonstrates native idempotency, dynamic variable injection, and modular server configuration without manual SSH execution.

### Level 3: Cloud-Native IaC on AWS (Terraform + Ansible) - _Coming Soon_

- **The Architecture:** Production-grade AWS Cloud Infrastructure (Custom VPC, Security Groups, and EC2 Instances).
- **The Tooling:** Terraform for AWS hardware and network provisioning, handing off to Ansible for software configuration.
- **The Lesson:** Demonstrates immutable, cloud-provider infrastructure. Terraform interacts directly with the AWS API to architect the cloud environment, while Ansible securely connects to the live EC2 instances to configure the application stack.

---

## 🛠 Testing Environments

To ensure a clean, reproducible setup while managing costs:

- **Levels 1 & 2 (Local Testing):** Utilizes **Vagrant** with the **KVM/libvirt** hypervisor to spin up isolated, cost-free VMs locally.
- **Level 3 (Cloud Deployment):** Targets **Amazon Web Services (AWS)** using standard API credentials to provision real cloud infrastructure.
