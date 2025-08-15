#!/usr/bin/env bash
set -euo pipefail

# שימוש: bash scripts/split_and_fix_s3.sh [ROOT]
ROOT="${1:-$HOME/asterra-devops-assignment}"
ENV_DIR="$ROOT/infra/terraform/envs/prod"

echo ">>> Using Terraform env dir: $ENV_DIR"
cd "$ENV_DIR"

# 0) גיבוי הקובץ הענק אם קיים
if [ -f "network.tf" ]; then
  ts=$(date +%Y%m%d-%H%M%S)
  mv network.tf "network.monolith.tf.bak.$ts"
  echo ">>> Backed up network.tf -> network.monolith.tf.bak.$ts"
fi

# 1) VPC
cat > network_vpc.tf <<'EOF'
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "${var.name_prefix}-vpc" }
}
EOF

# 2) ציבורי: IGW + Subnets + RouteTable + Assoc
cat > network_public.tf <<'EOF'
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.name_prefix}-igw" }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/20"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.name_prefix}-public-a" }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.16.0/20"
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.name_prefix}-public-b" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.name_prefix}-rt-public" }
}

resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_a_assoc" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b_assoc" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

output "public_subnet_ids" {
  value = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}
EOF

# 3) SG ציבורי לאפליקציות
cat > sg_public.tf <<'EOF'
resource "aws_security_group" "app_public_sg" {
  name        = "${var.name_prefix}-app-public-sg"
  description = "Allow HTTP from the Internet; all egress"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name_prefix}-app-public-sg" }
}

output "app_public_sg_id" {
  value = aws_security_group.app_public_sg.id
}
EOF

# 4) פרטי + SG ל-RDS
cat > network_private_rds.tf <<'EOF'
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.128.0/20"
  availability_zone = "${var.region}a"
  tags              = { Name = "${var.name_prefix}-private-a" }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.144.0/20"
  availability_zone = "${var.region}b"
  tags              = { Name = "${var.name_prefix}-private-b" }
}

resource "aws_security_group" "rds_sg" {
  name        = "${var.name_prefix}-rds-sg"
  description = "Allow Postgres from app SG only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Postgres from app_public_sg"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_public_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name_prefix}-rds-sg" }
}

output "private_subnet_ids" {
  value = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

output "rds_sg_id" {
  value = aws_security_group.rds_sg.id
}
EOF

# 5) S3: ingest + public + ריכוך חסימות + מדיניות עם תלות
cat > s3.tf <<'EOF'
resource "aws_s3_bucket" "ingest" {
  bucket        = "${var.name_prefix}-ingest"
  force_destroy = true
  tags          = { Name = "${var.name_prefix}-ingest" }
}

resource "aws_s3_bucket_public_access_block" "ingest_block" {
  bucket                  = aws_s3_bucket.ingest.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "public" {
  bucket        = "${var.name_prefix}-public"
  force_destroy = true
  tags          = { Name = "${var.name_prefix}-public" }
}

resource "aws_s3_bucket_website_configuration" "public_site" {
  bucket = aws_s3_bucket.public.id
  index_document { suffix = "index.html" }
}

# ריכוך חסימות ברמת החשבון (לדמו; לפרוד עדיף CloudFront + OAC)
resource "aws_s3_account_public_access_block" "account_relax" {
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = false
  restrict_public_buckets = false
}

# ריכוך חסימות על הדלי הציבורי
resource "aws_s3_bucket_public_access_block" "public_allow" {
  bucket                  = aws_s3_bucket.public.id
  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

# מדיניות קריאה ציבורית לאובייקטים
resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.public.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = "*",
      Action    = ["s3:GetObject"],
      Resource  = ["${aws_s3_bucket.public.arn}/*"]
    }]
  })

  # חשוב: לדאוג שריכוך החסימות יקרה לפני שמגדירים מדיניות
  depends_on = [
    aws_s3_account_public_access_block.account_relax,
    aws_s3_bucket_public_access_block.public_allow
  ]
}

output "s3_ingest_bucket" { 
  value = aws_s3_bucket.ingest.bucket 
}

output "s3_public_bucket" { 
  value = aws_s3_bucket.public.bucket 
}

output "s3_public_website_endpoint" { 
  value = aws_s3_bucket_website_configuration.public_site.website_endpoint 
}
EOF

echo ">>> Created split Terraform files:"
echo "  - network_vpc.tf (VPC)"
echo "  - network_public.tf (Public subnets, IGW, routes)"
echo "  - sg_public.tf (Application security group)"
echo "  - network_private_rds.tf (Private subnets, RDS SG)"
echo "  - s3.tf (S3 buckets with proper public access configuration)"

echo ">>> S3 configuration includes:"
echo "  - Private ingest bucket with full blocking"
echo "  - Public bucket with website hosting"
echo "  - Account-level public access block relaxation"
echo "  - Bucket-level public access configuration"
echo "  - Public read policy with proper dependencies"

echo ">>> Ready to run: terraform plan" 