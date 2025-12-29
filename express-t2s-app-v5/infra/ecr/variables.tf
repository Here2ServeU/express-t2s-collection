############################################
# VARIABLES FOR ECR MODULE
############################################

variable "region" {
  description = "AWS region for ECR repositories"
  type        = string
}

variable "express_repo_name" {
  description = "ECR repo name for Express Web App"
  type        = string
  default     = "t2s-express-app"
}

variable "aiops_repo_name" {
  description = "ECR repo name for AIOps API"
  type        = string
  default     = "aiops-api"
}
