# Level 1: The "Startup Monolith"

This directory represents the first phase of the Infrastructure as Code (IaC) evolution. The goal is to provision a production-ready web application as fast as possible on a single server.

## 🏗 Architecture & Stack

- **Environment:** A single Ubuntu 22.04 LTS Virtual Machine.
- **Web Server:** Nginx (acting as a reverse proxy).
- **Application:** Node.js (v24 via NVM) managed by PM2.
- **Database:** PostgreSQL (installed via official Apt repository).
- **Cache:** Redis (installed via official Apt repository).

## How to Run Locally

This project uses **Vagrant** and the **KVM/libvirt** hypervisor to simulate a raw cloud virtual machine. Docker is intentionally avoided here because containers do not natively run `systemd`, which is required to test OS-level service configurations.

1. Ensure you have Vagrant and KVM/libvirt installed on your Linux host.

2. Boot the virtual machine:

```bash
vagrant up --provider=libvirt
```

3. SSH into the isolated environment:

```bash
vagrant ssh
```

4. Execute the provisioning script as root:

```bash
sudo bash /vagrant/bootstrap.sh
```

5. View the live application at http://localhost:8080.
