data "aws_caller_identity" "current" {}

resource "aws_ecr_repository" "this" {
  name                 = var.repo_name
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = var.scan_on_push }
  force_delete = true
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last N images",
        selection    = {
          tagStatus     = "any",
          countType     = "imageCountMoreThan",
          countNumber   = var.lifecycle_keep
        },
        action = { type = "expire" }
      }
    ]
  })
}

output "repository_url" {
  value = aws_ecr_repository.this.repository_url
}
output "account_id" {
  value = data.aws_caller_identity.current.account_id
}
