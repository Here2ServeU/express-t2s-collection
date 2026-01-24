# 1. Create the OIDC Identity Provider for GitHub Actions
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

# 2. Create the IAM Role with a Trust Policy for OIDC
resource "aws_iam_role" "gha_eks_deploy_role" {
  name = "t2s-gha-eks-deploy-prod"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
          }
          StringLike = {
            # Updated to point to the current repository: express-t2s-app-v4
            "token.actions.githubusercontent.com:sub": "repo:Here2ServeU/express-t2s-app-v4:*"
          }
        }
      }
    ]
  })
}

# 3. Attach updated EKS Permissions Policy to the Role
resource "aws_iam_role_policy" "gha_deployment_policy" {
  name = "T2SGHADeploymentPolicy"
  role = aws_iam_role.gha_eks_deploy_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEC2AndVPCManagement"
        Effect = "Allow"
        Action = [
          "ec2:CreateVpc",
          "ec2:CreateTags",
          "ec2:Describe*",
          "ec2:*Vpc*",
          "ec2:*Subnet*",
          "ec2:*Gateway*",
          "ec2:*Route*",
          "ec2:*Address*",
          "ec2:*SecurityGroup*",
          "ec2:*Tags*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowLoadBalancerManagement"
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowIAMFullManagement"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:GetRolePolicy",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:TagRole",
          "iam:PassRole",
          "iam:CreateServiceLinkedRole",
          "iam:GetOpenIDConnectProvider"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchLogsFull"
        Effect = "Allow"
        Action = [
          "logs:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowS3AndDynamoState"
        Effect = "Allow"
        Action = [
          "s3:*",
          "dynamodb:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowECRandEKS"
        Effect = "Allow"
        Action = [
          "ecr:*",
          "eks:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowKMSForEKS"
        Effect = "Allow"
        Action = [
          "kms:DescribeKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
      }
    ]
  })
}
