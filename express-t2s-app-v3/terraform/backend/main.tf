provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "tf_backend" {
  bucket = var.bucket_name
  acl    = "private"
  versioning {
    enabled = true
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
