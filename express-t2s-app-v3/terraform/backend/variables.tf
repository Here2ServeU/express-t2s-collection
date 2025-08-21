variable "bucket_name" {
  description = "The exact name of the S3 bucket for Terraform backend"
  type        = string
}

variable "lock_table" {
  description = "The name of the DynamoDB table for Terraform state locking"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment tag (e.g., dev, prod)"
  type        = string
}
