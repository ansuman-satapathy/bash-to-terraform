This directory represents the third phase of the IaC (Infrastructure as Code) Evolution. It transitions our infrastructure from local, hypervisor-based virtual machines (Vagrant) to a production-grade cloud environment hosted on AWS.

We used **Terraform** to architect the physical network and compute layer, and reused our **Ansible** logic from Level 2 to handle the configuration management. This perfectly demonstrates the industry-standard **Separation of Concerns**: Terraform builds the house; Ansible moves the furniture in.

## The Architecture

We built a custom Virtual Private Cloud (VPC) from scratch, enforcing strict security boundaries:

- **Public Subnet (Web Tier):** Hosts the Nginx/Node.js frontend. It has a public IP and an Internet Gateway attached.
- **Private Subnet (Data Tier):** Hosts the PostgreSQL database and Redis cache. These instances have no public IP addresses and are completely shielded from the internet.
- **NAT Gateway:** Provisioned in the public subnet to allow the private database and cache servers to securely reach the internet to download `apt` packages without exposing them to inbound internet traffic.
- **Bastion Host Routing:** To configure the private database and cache servers, we configured Ansible to securely tunnel through the public Web Server via SSH `ProxyCommand`.

## The Evolution & Code Reuse

The core philosophy of this project is avoiding duplicated effort. Here is how logic progressed through the levels:

1. **Level 1 (Bash/Manual):** We learned the raw commands required to configure the OS, install dependencies, and run the app.
2. **Level 2 (Ansible/Vagrant):** We translated those raw bash commands into declarative, idempotent Ansible **Roles**. We abstracted the configuration away from the hardware.
3. **Level 3 (Terraform/AWS):** Because Ansible is infrastructure-agnostic, we **reused 100% of the Level 2 Ansible Roles, `site.yml`, and `ansible.cfg`**. The application code does not care that it now lives in AWS instead of a local Vagrant box. We simply generated a new `inventory.ini` pointing to the live AWS IPs, and the exact same playbooks configured a distributed cloud network.

## Cloud Migration Quirks

Migrating from a local hypervisor to AWS revealed several critical environment differences that required strategic refactoring:

- **The Phantom User:** Local Vagrant boxes default to a `vagrant` OS user, whereas AWS Ubuntu AMIs default to `ubuntu`. Ansible tasks regarding directory ownership (`chown`) and execution privilege (`become_user`) must be updated to match the cloud provider's default AMI user.
- **NAT Gateway Necessity:** A private subnet in AWS is truly private. Without explicitly routing outbound traffic through a NAT Gateway, private servers will silently timeout during `apt-get update` tasks.
- **Dynamic IP Injection:** Hardcoding IP addresses for backend services (like `PG_HOST: 192.168.x.x`) fails in the cloud because AWS dynamically assigns IPs on creation. We refactored the Ansible tasks to use magic variables (`{{ groups['db'][0] }}`) to dynamically inject the live AWS IPs directly from the `inventory.ini` file into the Node.js environment.
- **VPC CIDR Trust:** Internal services like PostgreSQL default to trusting specific subnets (e.g., in `pg_hba.conf`). These must be updated to trust the overarching AWS VPC CIDR block (e.g., `10.0.0.0/16`) to allow cross-subnet communication.
- **Execution Pathing:** Separating Terraform and Ansible into dedicated directories shifts the relative pathing. File synchronization modules (like Ansible's `synchronize`) require an extra directory traversal (`../../`) to locate code stored at the project root.

## What I Learned

Building this architecture from the ground up solidified several core Platform Engineering concepts:

- **Modular Terraform:** Transitioned from hardcoded scripts to production-grade modules using `variables.tf` (schemas), `terraform.tfvars` (injected values), and `locals.tf` (reusable naming conventions).
- **State Management:** Mastered how Terraform tracks hardware via the `terraform.tfstate` file, allowing for seamless updates and cost-saving `terraform destroy` commands.
- **Dynamic Data Sources:** Used AWS AMI data blocks to automatically fetch the latest Ubuntu 24.04 LTS images, preventing infrastructure rot.
- **Cloud Security Groups:** Replaced older inline rules with modern `aws_vpc_security_group_ingress_rule` resources, ensuring the database only accepts traffic explicitly from the Web tier's security group.
- **SSH Key Management & Tunneling:** Successfully managed external `.pem` key pairs and configured Ansible's SSH daemon to jump through a bastion host to reach private subnets.

## How to Run This Project

### 1. Provision the Infrastructure

```bash
# Generate the SSH Key in AWS (ensure your CLI is authenticated)
aws ec2 create-key-pair --region us-east-1 --key-name "aws-project-key" --query 'KeyMaterial' --output text > ~/Creds/aws-project-key.pem
chmod 400 ~/Creds/aws-project-key.pem

# Build the AWS VPC and EC2 Instances
terraform init
terraform apply
```

### 2. Configure the Operating Systems

Take the IPs outputted by Terraform and place them in the `ansible/inventory.ini` file.

```bash
cd ansible
ansible-playbook -i inventory.ini site.yml
```

### 3. Clean Up (Avoid AWS Charges)

```bash
cd ..
terraform destroy
```
