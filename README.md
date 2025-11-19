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

## Configuration Guide

### Core Variables (group_vars/all.yml)

1. **AWS Configuration**
```yaml
# AWS Region
aws_region: us-east-1          # Change to your preferred region
project_tag: webdev           # Used for resource tagging and identification

# Instance Configuration
instance_type: t2.micro       # Change based on your needs (e.g., t2.small, t2.medium)
debian_ami_id: ami-123456     # Update with your region's Debian AMI ID
```

2. **Security Configuration**
```yaml
# Access Control
ssh_cidr: 0.0.0.0/0          # Restrict to your IP range (e.g., 203.0.113.0/24)
web_http_cidr: 0.0.0.0/0     # Restrict if needed (e.g., corporate network)

# SSH Access
ansible_user: admin          # EC2 instance username
ansible_ssh_private_key_file: "/home/admin/.ssh/labsuser.pem"  # Path to your key
```

3. **Database Configuration**
```yaml
# MariaDB Settings
db_name: Test1              # Your database name
db_user: admin             # Database admin username
db_password: IG2IUser      # Change this to a secure password
db_port: 3306              # Change if needed
```

4. **Subnet Configuration (IMPORTANT pour la sécurité de la DB)**

Pour garantir que la base de données n'aura **jamais d'IP publique**, il est impératif d'utiliser un **subnet privé** pour la DB :

- Dans `group_vars/all.yml`, renseignez la variable `private_subnet_id` avec l'ID d'un subnet privé de votre VPC :
  ```yaml
  private_subnet_id: "subnet-0abc1234def567890"  # Remplacez par l'ID de votre subnet privé
  ```
- Un subnet privé est un subnet :
  - qui n'est pas associé à une Internet Gateway (IGW)
  - ou qui a l'option "auto-assign public IP" désactivée

**Comment trouver/créer un subnet privé sur AWS ?**
1. Console AWS > VPC > Subnets
2. Repérez un subnet sans IGW et sans auto-assign public IP, ou créez-en un nouveau
3. Copiez son ID (ex: subnet-0abc1234def567890)
4. Renseignez-le dans `group_vars/all.yml` sous `private_subnet_id`

Si cette variable est vide, la DB sera créée dans le subnet par défaut (souvent public), ce qui n'est pas recommandé !

Pour Bastion/Web, vous pouvez utiliser un subnet public (variable `public_subnet_id` si besoin).

### Instance Naming

Security groups and instances are automatically named using this pattern:
- Bastion: `{{ project_tag }}-bastion-sg`
- Web: `{{ project_tag }}-web-sg`
- DB: `{{ project_tag }}-db-sg`

Example with `project_tag: myproject`:
- `myproject-bastion-sg`
- `myproject-web-sg`
- `myproject-db-sg`

### AWS Inventory Configuration (inventory_aws_ec2.yml)

```yaml
plugin: aws_ec2
regions:
  - us-east-1               # Match with aws_region in all.yml
filters:
  tag:Project: webdev       # Match with project_tag in all.yml
  instance-state-name: ["running"]
```

### Security Customization

1. **Bastion Access**
   - Edit `ssh_cidr` in `all.yml` to restrict SSH access:
   ```yaml
   ssh_cidr: 203.0.113.0/24  # Your office/home IP range
   ```

2. **Web Access**
   - Edit `web_http_cidr` in `all.yml` to restrict HTTP access:
   ```yaml
   web_http_cidr: 10.0.0.0/8  # Your corporate network
   ```

3. **Database Security**
   - Change default credentials in `all.yml`:
   ```yaml
   db_user: myapp
   db_password: "Strong-Password-Here"
   ```

### Instance Type Selection

Choose instance types based on your needs:
```yaml
instance_type: t2.micro    # Development/Testing
# OR
instance_type: t2.small    # Small production
# OR
instance_type: t2.medium   # Medium production
```

Cost considerations (as of November 2025):
- t2.micro: Free tier eligible
- t2.small: $0.023 per hour
- t2.medium: $0.0464 per hour

### Custom AMI Selection

To use a different Debian AMI:
1. Visit AWS AMI Catalog
2. Search for Debian images in your region
3. Copy the AMI ID
4. Update in `all.yml`:
```yaml
debian_ami_id: ami-your-chosen-id
```

### Network Configuration

By default, instances use the default VPC. To use a custom VPC:
1. Create your VPC in AWS
2. Add to `all.yml`:
```yaml
vpc_id: vpc-xxxxx
web_subnet_id: subnet-xxxxx
db_subnet_id: subnet-yyyyy
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
