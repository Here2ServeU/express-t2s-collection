############################################
# OUTPUTS
############################################

output "express_web_app_repository_url" {
  description = "ECR URL for the Express Web App"
  value       = aws_ecr_repository.express_web_app.repository_url
}

output "aiops_api_repository_url" {
  description = "ECR URL for the AIOps API"
  value       = aws_ecr_repository.aiops_api.repository_url
}
