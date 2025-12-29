############################################
# AWS ECR – MULTI-REPO SETUP
# Creates:
#   - Express Web App repo
#   - AIOps API repo
############################################

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

provider "aws" {
  region = var.region
}

############################################
# EXPRESS WEB APP REPOSITORY
############################################
resource "aws_ecr_repository" "express_web_app" {
  name = var.express_repo_name

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

############################################
# AIOPS API REPOSITORY
############################################
resource "aws_ecr_repository" "aiops_api" {
  name = var.aiops_repo_name

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

############################################
# LIFECYCLE POLICIES (Keep last 20 images)
############################################

resource "aws_ecr_lifecycle_policy" "express_web_app" {
  repository = aws_ecr_repository.express_web_app.name

  policy = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 20 images",
      "action": { "type": "expire" },
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 20
      }
    }
  ]
}
EOF
}

resource "aws_ecr_lifecycle_policy" "aiops_api" {
  repository = aws_ecr_repository.aiops_api.name

  policy = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 20 images",
      "action": { "type": "expire" },
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 20
      }
    }
  ]
}
EOF
}
