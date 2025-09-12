provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "tf_backend" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = {
    Name        = "Terraform Backend Bucket"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "tf_backend_versioning" {
  bucket = aws_s3_bucket.tf_backend.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "tf_lock" {
  name         = var.lock_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
