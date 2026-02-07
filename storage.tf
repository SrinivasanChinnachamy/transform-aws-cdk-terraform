# Storage Layer - S3 and DynamoDB Resources
# Converted from constructs/storage_construct.py

# S3 Bucket for storing processing results
resource "aws_s3_bucket" "data_bucket" {
  bucket_prefix = "${var.project_name}-data-"
  
  # RemovalPolicy.DESTROY → force_destroy = true
  force_destroy = true

  tags = {
    Name        = "DataBucket"
    Component   = "Storage"
    Description = "S3 bucket for storing processing results"
  }
}

# S3 Bucket versioning configuration
resource "aws_s3_bucket_versioning" "data_bucket_versioning" {
  bucket = aws_s3_bucket.data_bucket.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "data_bucket_lifecycle" {
  bucket = aws_s3_bucket.data_bucket.id

  rule {
    id     = "auto-delete-objects"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# S3 Bucket public access block (security best practice)
resource "aws_s3_bucket_public_access_block" "data_bucket_pab" {
  bucket = aws_s3_bucket.data_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB Table for request metadata and status tracking
resource "aws_dynamodb_table" "metadata_table" {
  name         = "${var.project_name}-metadata-table"
  billing_mode = "PAY_PER_REQUEST"  # BillingMode.PAY_PER_REQUEST
  hash_key     = "requestId"

  attribute {
    name = "requestId"
    type = "S"  # STRING type
  }

  # RemovalPolicy.DESTROY - allow table deletion
  deletion_protection_enabled = false

  tags = {
    Name        = "MetadataTable"
    Component   = "Storage"
    Description = "DynamoDB table for request metadata and status tracking"
  }
}
