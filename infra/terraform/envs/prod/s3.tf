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
