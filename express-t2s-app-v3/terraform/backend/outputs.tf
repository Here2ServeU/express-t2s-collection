output "s3_bucket_name" {
  value       = var.bucket_name
  description = "S3 bucket used for remote backend"
}

output "dynamodb_table_name" {
  value       = var.lock_table
  description = "DynamoDB table used for state locking"
}
