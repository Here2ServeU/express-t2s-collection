variable "region" {
  default = "us-east-1"
}

variable "bucket_name" {
  description = "The name of the S3 bucket for storing Terraform state"
  type        = string
}

variable "lock_table" {
  description = "The name of the DynamoDB table for state locking"
  type        = string
}
