output "push_command" {
  value = "docker push ${aws_ecr_repository.this.repository_url}:${var.image_tag}"
}
