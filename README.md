# ASTERRA DevOps Assignment – Learning Project

This repository contains my end-to-end AWS infrastructure implementation for the Asterra DevOps learning project.  
The goal was to build a **secure, highly available, and production-ready environment** using Terraform, AWS services, and best practices.

## 📌 Project Goals
- Learn and practice **Infrastructure as Code** with Terraform.
- Deploy a **VPC** with public and private subnets across multiple Availability Zones.
- Configure **bastion host** access to private resources.
- Deploy an **RDS PostgreSQL** instance with PostGIS extensions.
- Create and configure **S3 buckets** for public static hosting and secure data ingest.

## 🏗 Architecture Overview
![AWS Architecture](diagrams/architecture.png)

## 🔐 Security Highlights
- Bastion host in public subnet for SSH into private resources.
- RDS accessible **only** from bastion host or application SG.
- S3 buckets configured with correct public/private ACLs and policies.
- No direct internet access for private subnets.

## 📦 Terraform Structure
```
.
├── main.tf
├── vpc.tf
├── rds.tf
├── bastion.tf
├── s3.tf
├── variables.tf
├── outputs.tf
├── diagrams/
│ └── architecture.png
└── scripts/
└── init_postgis.sh
```

## 🚀 Deployment Steps
```bash
terraform init
terraform apply
```

## 📊 Outputs Example
```
app_public_sg_id = "sg-0816427004a3aa484"
bastion_public_ip = "3.123.19.20"
rds_endpoint = "asterra-demo-pg.cxyq286oy8yk.eu-central-1.rds.amazonaws.com"
s3_public_website_endpoint = "asterra-demo-public.s3-website.eu-central-1.amazonaws.com"
```

