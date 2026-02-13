variable "bucket_name" {
  description = "The exact name of the S3 bucket for Terraform backend"
  type        = string
  default     = "express-t2s-app-terraform-state-dev"
}

variable "lock_table" {
  description = "The name of the DynamoDB table for Terraform state locking"
  type        = string
  default     = "express-t2s-app-state-lock"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment tag (e.g., dev, prod)"
  type        = string
  default     = "dev"
}
