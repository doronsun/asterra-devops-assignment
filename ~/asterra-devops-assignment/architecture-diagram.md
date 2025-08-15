# AWS Infrastructure Architecture Diagram

## System Overview
This diagram represents the AWS infrastructure we built with Terraform, showing the VPC, subnets, security groups, and resource relationships.

```mermaid
graph TB
    %% Internet
    Internet[🌐 Internet]
    
    %% VPC Container
    subgraph VPC["🔷 VPC (10.0.0.0/16)"]
        
        %% Public Subnets
        subgraph PublicSubnets["🌍 Public Subnets"]
            PublicA["📡 Public Subnet A<br/>10.0.0.0/20<br/>eu-central-1a"]
            PublicB["📡 Public Subnet B<br/>10.0.16.0/20<br/>eu-central-1b"]
        end
        
        %% Private Subnets
        subgraph PrivateSubnets["🔒 Private Subnets"]
            PrivateA["🔐 Private Subnet A<br/>10.0.128.0/20<br/>eu-central-1a"]
            PrivateB["🔐 Private Subnet B<br/>10.0.144.0/20<br/>eu-central-1b"]
        end
        
        %% Internet Gateway
        IGW["🌐 Internet Gateway<br/>asterra-demo-igw"]
        
        %% Route Tables
        PublicRT["🗺️ Public Route Table<br/>0.0.0.0/0 → IGW"]
        PrivateRT["🗺️ Private Route Table<br/>No Internet Access"]
        
        %% Bastion Host
        Bastion["🖥️ Bastion Host<br/>EC2 Instance<br/>Public IP"]
        
        %% RDS Database
        RDS["🗄️ RDS PostgreSQL<br/>+ PostGIS Extension<br/>Multi-AZ"]
        
        %% Security Groups
        BastionSG["🛡️ Bastion Security Group<br/>• SSH (22) from Internet<br/>• SSH (22) to Private"]
        RDSSG["🛡️ RDS Security Group<br/>• PostgreSQL (5432) from Bastion"]
        AppSG["🛡️ App Security Group<br/>• HTTP (80) from Internet"]
        
        %% Route Table Associations
        PublicRT -.->|Associated| PublicA
        PublicRT -.->|Associated| PublicB
        PrivateRT -.->|Associated| PrivateA
        PrivateRT -.->|Associated| PrivateB
    end
    
    %% S3 Buckets (Outside VPC)
    subgraph S3["📦 S3 Storage"]
        PublicS3["🌐 Public Website Bucket<br/>asterra-demo-public<br/>• Static Website Hosting<br/>• Public Read Access"]
        IngestS3["🔒 Ingest Bucket<br/>asterra-demo-ingest<br/>• Private Access Only<br/>• Block Public Access"]
    end
    
    %% Connections
    Internet -->|HTTP (80)| PublicS3
    Internet -->|SSH (22)| BastionSG
    Internet -->|HTTP (80)| AppSG
    
    %% VPC Internal Connections
    IGW --> PublicRT
    Bastion -->|SSH (22)| RDS
    Bastion -->|psql (5432)| RDS
    
    %% Security Group Associations
    Bastion -.->|Protected by| BastionSG
    RDS -.->|Protected by| RDSSG
    
    %% S3 Access
    Bastion -.->|S3 API| IngestS3
    Bastion -.->|S3 API| PublicS3
    
    %% Styling
    classDef vpcStyle fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef publicStyle fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    classDef privateStyle fill:#ffcdd2,stroke:#c62828,stroke-width:2px
    classDef securityStyle fill:#fff3e0,stroke:#ef6c00,stroke-width:2px
    classDef s3Style fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    classDef internetStyle fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    
    class VPC vpcStyle
    class PublicSubnets,PublicA,PublicB publicStyle
    class PrivateSubnets,PrivateA,PrivateB privateStyle
    class BastionSG,RDSSG,AppSG securityStyle
    class S3,PublicS3,IngestS3 s3Style
    class Internet,IGW internetStyle
```

## Key Components

### 🏗️ **Network Infrastructure**
- **VPC**: `10.0.0.0/16` with DNS support enabled
- **Public Subnets**: 2 subnets across availability zones with auto-assign public IPs
- **Private Subnets**: 2 subnets across availability zones for secure resources
- **Internet Gateway**: Provides internet access to public subnets

### 🛡️ **Security Groups**
- **Bastion SG**: Allows SSH from internet and to private subnets
- **RDS SG**: Allows PostgreSQL access only from Bastion
- **App SG**: Allows HTTP access from internet

### 🗄️ **Database**
- **RDS PostgreSQL**: Multi-AZ deployment with PostGIS extension
- **Private Placement**: Located in private subnets for security
- **Bastion Access**: Only accessible through Bastion host

### 📦 **Storage**
- **Public S3 Bucket**: Static website hosting with public read access
- **Ingest S3 Bucket**: Private bucket with full access blocking
- **Website Endpoint**: `asterra-demo-public.s3-website.eu-central-1.amazonaws.com`

### 🔐 **Access Control**
- **Bastion Host**: Single point of SSH access to private resources
- **No Direct Internet**: Private subnets have no direct internet access
- **S3 Policies**: Proper bucket policies with public access controls

## Security Features

✅ **Network Isolation**: Private subnets isolated from internet  
✅ **Bastion Access**: Controlled SSH access through single point  
✅ **Database Security**: RDS only accessible through Bastion  
✅ **S3 Security**: Proper public/private bucket configuration  
✅ **Security Groups**: Least privilege access control  
✅ **Multi-AZ**: High availability across availability zones  

## Terraform Outputs

```hcl
vpc_id = "vpc-02669bf649c7a5f00"
public_subnet_ids = ["subnet-0024f23136bdc2c72", "subnet-0a5f48a27ec6d4d39"]
private_subnet_ids = ["subnet-0f723ef5946440ea3", "subnet-0fd2a85a1217488f1"]
app_public_sg_id = "sg-0816427004a3aa484"
rds_sg_id = "sg-084f5a85a2a05e7ff"
s3_ingest_bucket = "asterra-demo-ingest"
s3_public_bucket = "asterra-demo-public"
s3_public_website_endpoint = "asterra-demo-public.s3-website.eu-central-1.amazonaws.com"
``` 