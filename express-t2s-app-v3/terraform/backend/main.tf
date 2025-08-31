terraform {
  required_version = ">= 1.3.0"
  backend "s3" {
    bucket         = "t2s-terraform-state"
    key            = "eks/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "t2s-terraform-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}
