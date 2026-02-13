provider "aws" {
  region = var.region
}

resource "aws_ecr_repository" "app" {
  name                 = var.repo_name
  image_tag_mutability = "MUTABLE"
  force_delete         = false

  # Add this to see if images have vulnerabilities
  image_scanning_configuration {
    scan_on_push = true
  }

  # Add this for encryption
  encryption_configuration {
    encryption_type = "AES256"
  }
}
