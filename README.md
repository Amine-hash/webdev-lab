# Web Development Lab with AWS Infrastructure

This repository contains Ansible playbooks to manage a web development infrastructure on AWS, including:
- Bastion host for secure access
- Web server running Apache/PHP
- Database server running MariaDB
- Security groups and networking configuration

## Project Structure

```
.
├── group_vars/
│   ├── all.yml                  # Global variables
│   ├── tag_Role_Bastion.yml    # Bastion-specific variables
│   ├── tag_Role_DB.yml         # Database-specific variables
│   └── tag_Role_Web.yml        # Web server-specific variables
├── inventory_aws_ec2.yml        # Dynamic AWS inventory configuration
├── roles/
│   ├── bastion/                # Bastion host configuration
│   ├── database/               # MariaDB server configuration
│   ├── infra/                  # AWS infrastructure management
│   └── webserver/              # Apache/PHP configuration
├── site.yml                    # Main playbook for infrastructure creation and configuration
└── destroy.yml                 # Playbook for infrastructure destruction
```

## Prerequisites

- Ansible
- Python 3
- boto3 (AWS SDK for Python)
- AWS credentials configured

## Usage

### Creating and Configuring Infrastructure

To create and configure the complete infrastructure:

```bash
ansible-playbook -i inventory_aws_ec2.yml site.yml -e "infra_state=present"
```

This will:
1. Create all required security groups
2. Launch EC2 instances (Bastion, Web, DB)
3. Configure the Bastion host
4. Install and configure MariaDB on the database server
5. Set up Apache/PHP on the web server

### Destroying Infrastructure

To destroy all infrastructure components:

```bash
ansible-playbook -i inventory_aws_ec2.yml destroy.yml -e "infra_state=absent"
```

This will:
1. Terminate all EC2 instances
2. Remove all security groups
3. Clean up associated resources

## Variables

Key variables can be configured in `group_vars/all.yml`:
- `project_tag`: Project name for resource tagging
- `aws_region`: AWS region
- `instance_type`: EC2 instance type
- Database credentials and configuration
- Security group settings

## Security

- All SSH access is routed through the Bastion host
- Database is only accessible from the web server
- Security groups enforce least-privilege access
- SSH key pairs are managed securely
