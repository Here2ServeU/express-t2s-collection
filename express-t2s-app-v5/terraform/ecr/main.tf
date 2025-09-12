provider "aws" {
  region = var.region
}

resource "aws_ecr_repository" "app" {
  name         = var.repo_name
  force_delete = true
}