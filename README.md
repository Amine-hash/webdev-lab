# AWS Web Development Lab Infrastructure

Infrastructure as Code project using Ansible to deploy a secure web development environment on AWS.

## Architecture

```plaintext
                                     Private Network (172.31.x.x)
┌──────────────┐     SSH     ┌──────────────┐     3306      ┌──────────────┐
│    Bastion   │ ◄─────────► │  Web Server  │ ◄──────────── │ Database     │
│              │     22      │  (Apache/PHP) │               │ (MariaDB)    │
│ Public IP    │             │              │               │              │
└──────────────┘             └──────────────┘               └──────────────┘
       ▲                            ▲
       │                            │
       └────────────────┐          │
                        │          │
                     SSH (22)    HTTP (80)
                        │          │
                        ▼          ▼
                    Admin/Dev    Users
```

## Features

- **Secure Architecture**:
  - Bastion host as single entry point
  - Private network for web and database servers
  - Security groups with least privilege access

- **Web Stack**:
  - Apache with PHP support
  - MariaDB database
  - Sample web application

- **Infrastructure Management**:
  - Dynamic AWS inventory
  - Idempotent deployments
  - Easy destroy/recreate cycle

## Prerequisites

1. AWS Account and credentials configured
2. Ansible installed (version 2.9+)
3. Python boto3 library installed:
   ```bash
   pip install boto3
   ```
4. AWS credentials configured in ~/.aws/credentials:
   ```ini
   [default]
   aws_access_key_id = YOUR_ACCESS_KEY
   aws_secret_access_key = YOUR_SECRET_KEY
   ```

## Quick Start

### 1. Clone the Repository
```bash
git clone <repository-url>
cd webdev-lab
```

### 2. Configure Variables
Review and adjust variables in:
- `group_vars/all.yml` for global settings
- `inventory_aws_ec2.yml` for AWS inventory configuration

### 3. Deploy Infrastructure
```bash
ansible-playbook -i inventory_aws_ec2.yml site.yml -e "infra_state=present"
```

### 4. Destroy Infrastructure
```bash
ansible-playbook -i localhost, destroy.yml
```

## Components

### Bastion Host
- Entry point for SSH access
- Security group allowing inbound SSH from admin IPs
- Forwards SSH connections to private instances

### Web Server
- Apache + PHP
- Security group allowing HTTP from internet
- SSH access only through bastion
- Sample PHP pages for testing

### Database Server
- MariaDB
- Private network only
- Access restricted to web server
- Security group allowing port 3306 only from web server

## Security Groups

1. **Bastion SG**:
   - Inbound: SSH (22) from admin IPs
   - Outbound: All allowed

2. **Web Server SG**:
   - Inbound: 
     - HTTP (80) from internet
     - SSH (22) from bastion
   - Outbound: All allowed

3. **Database SG**:
   - Inbound:
     - MariaDB (3306) from web server
     - SSH (22) from bastion
   - Outbound: All allowed

## Testing the Deployment

After deployment, you can access:
1. Web Server Public IP:
   - http://<web_public_ip>/info.php
   - http://<web_public_ip>/dump.table.php
   - http://<web_public_ip>/db_test.php

2. SSH Access:
   ```bash
   # To Bastion
   ssh -i ~/.ssh/labsuser.pem admin@<bastion_public_ip>
   
   # To Web/DB (via Bastion)
   ssh -J admin@<bastion_public_ip> admin@<private_ip>
   ```

## Cleaning Up

To destroy all resources:
```bash
ansible-playbook -i localhost, destroy.yml
```

This will:
1. Terminate all EC2 instances
2. Delete security groups in the correct order
3. Clean up associated resources
