# configure aws provider
provider "aws" {
  region = var.region
}

# configure backend
terraform {
  backend "s3" {
    bucket         = "t2s-s3-08252025"
    key            = "aws-eks.terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "my-lock-table"
  }
}
