output "ecr_repo_url" {
  value       = aws_ecr_repository.app.repository_url
  description = "URL of the created ECR repository"
}