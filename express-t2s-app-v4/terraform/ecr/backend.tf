terraform {
  backend "s3" {
    bucket         = "emmanuel-tf-state-09042025"      # Your S3 bucket name
    key            = "ecr/terraform.tfstate"  # For ECS state file (change to eks/... for EKS)
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"        # Your DynamoDB lock table
    encrypt        = true
  }
}
