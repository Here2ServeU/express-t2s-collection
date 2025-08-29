terraform {
  required_version = "~> 1.6.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.50" }
  }
  backend "s3" {
    bucket         = "YOUR_S3_BUCKET"
    key            = "ecr/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "YOUR_DDB_TABLE"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
}
