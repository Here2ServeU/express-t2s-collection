terraform {
  backend "s3" {
    bucket = "my-terraform-backend"
    key    = "ecs/terraform.tfstate"
    region = "us-east-1"
  }
}