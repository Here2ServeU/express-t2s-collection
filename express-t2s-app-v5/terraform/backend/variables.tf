variable "bucket_name" {
  description = "The exact name of the S3 bucket for Terraform backend"
  type        = string
  default     = "emmanuel-tf-state-09112025"
}

variable "lock_table" {
  description = "The name of the DynamoDB table for Terraform state locking"
  type        = string
  default     = "terraform-locks"
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
