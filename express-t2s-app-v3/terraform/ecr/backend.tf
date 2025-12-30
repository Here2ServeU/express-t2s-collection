terraform {
  backend "s3" {
    bucket         = "express-t2s-app-terraform-state-dev"
    key            = "ecr/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "express-t2s-app-state-lock"
    encrypt        = true
  }
}
