output "s3_bucket_name" {
  value = aws_s3_bucket.tf_backend.id
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.tf_lock.name
}
