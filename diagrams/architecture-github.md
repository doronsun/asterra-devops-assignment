# AWS Infrastructure Architecture

## Architecture Overview

```mermaid
graph TB
    Internet[Internet]
    
    subgraph AWS[AWS Region]
        subgraph VPC[VPC 10.0.0.0/16]
            subgraph AZA[Availability Zone A]
                PublicA[Public Subnet A<br/>10.0.0.0/20<br/>Bastion Host]
                PrivateA[Private Subnet A<br/>10.0.128.0/20<br/>RDS PostgreSQL]
            end
            
            subgraph AZB[Availability Zone B]
                PublicB[Public Subnet B<br/>10.0.16.0/20]
                PrivateB[Private Subnet B<br/>10.0.144.0/20]
            end
            
            IGW[Internet Gateway]
            
            subgraph SGs[Security Groups]
                BastionSG[Bastion SG<br/>SSH from Internet]
                RDSSG[RDS SG<br/>PostgreSQL from Bastion]
                AppSG[App SG<br/>HTTP from Internet]
            end
        end
        
        subgraph S3[S3 Storage]
            PublicS3[Public Website Bucket<br/>asterra-demo-public]
            IngestS3[Ingest Bucket<br/>asterra-demo-ingest]
        end
    end
    
    Internet -->|HTTP| PublicS3
    Internet -->|SSH| BastionSG
    Internet -->|HTTP| AppSG
    BastionSG -->|PostgreSQL| RDSSG
    IGW --> PublicA
    IGW --> PublicB
    
    classDef vpcStyle fill:#e3f2fd,stroke:#1976d2,stroke-width:3px
    classDef publicStyle fill:#c8e6c9,stroke:#2e7d32,stroke-width:2px
    classDef privateStyle fill:#ffcdd2,stroke:#c62828,stroke-width:2px
    classDef s3Style fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    
    class VPC vpcStyle
    class PublicA,PublicB publicStyle
    class PrivateA,PrivateB privateStyle
    class S3,PublicS3,IngestS3 s3Style
```

## Connection Flow

- **Internet → HTTP (80) → S3 Public Bucket** (Static Website)
- **Internet → SSH (22) → Bastion Host → PostgreSQL (5432) → RDS**
- **Internet → HTTP (80) → App Security Group → Public Subnets**

## Security Features

✅ **VPC Isolation** - All resources within private VPC  
✅ **Subnet Segmentation** - Public/Private separation  
✅ **No Direct Internet** - Private subnets isolated  
✅ **Multi-AZ** - High availability across AZs  
✅ **Security Groups** - Least privilege access control  
✅ **S3 Policies** - Proper public/private configuration  
✅ **Database Security** - RDS only accessible through Bastion  
✅ **Public Access Controls** - Account and bucket-level blocking  

## Terraform Outputs

```
vpc_id = "vpc-02669bf649c7a5f00"
public_subnet_ids = ["subnet-0024f23136bdc2c72", "subnet-0a5f48a27ec6d4d39"]
private_subnet_ids = ["subnet-0f723ef5946440ea3", "subnet-0fd2a85a1217488f1"]
app_public_sg_id = "sg-0816427004a3aa484"
rds_sg_id = "sg-084f5a85a2a05e7ff"
s3_ingest_bucket = "asterra-demo-ingest"
s3_public_bucket = "asterra-demo-public"
s3_public_website_endpoint = "asterra-demo-public.s3-website.eu-central-1.amazonaws.com"
``` 