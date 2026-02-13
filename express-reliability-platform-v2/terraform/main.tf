provider "aws" {
  region = var.region
}

resource "aws_ecr_repository" "app" {
  name = var.repo_name
}

resource "null_resource" "docker_push" {
  provisioner "local-exec" {
    command = <<EOT
      aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${var.account_id}.dkr.ecr.${var.region}.amazonaws.com
      docker build -t ${var.repo_name} ..
      docker tag ${var.repo_name}:latest ${var.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.repo_name}:latest
      docker push ${var.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.repo_name}:latest
    EOT
  }
}
