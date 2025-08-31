variable "aws_region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket for backend"
  type        = string
}

variable "lock_table" {
  description = "Name of the DynamoDB table for state locking"
  type        = string
}
