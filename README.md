
# Express T2S App Monorepo

## Overview

This monorepo supports the iterative development of Express-based applications for **Transformed 2 Succeed (T2S)**. Each version (`v1`, `v2`, etc.) reflects a progressive enhancement toward a secure, observable, production-ready platform on AWS using Terraform.

The platform is designed to be:
- Containerized using Docker
- Provisioned entirely with Terraform (ECR, ECS, EKS, IAM)
- Monitored using Prometheus, Grafana, CloudWatch
- Secured with IAM, Secrets Manager, and DevSecOps tools
- Cost-efficient, scalable, and AI-enabled (in v6)

---

## Goals

- Push Dockerized apps to AWS ECR
- Deploy services on ECS (Fargate) and EKS using Terraform
- Use GitHub Actions for CI/CD
- Integrate DevSecOps (Trivy, Checkov)
- Add observability and logging with Prometheus, Grafana, CloudWatch
- Support secure mentorship features (signup, automation)

---

## Features Implemented

Each version (e.g., `express-t2s-app-v1`) includes:
- Node.js + Express backend
- Static frontend with HTML form
- Dockerfile and CI/CD support
- Terraform modules for infrastructure provisioning

---

## Repo Structure

```
express-t2s-app/
├── express-t2s-app-v1/      
│   ├── public/
│   ├── index.js
│   └── terraform/
│       └── backend/        # Remote state S3 + DynamoDB setup
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars
│       ├── outputs.tf
│
├── express-t2s-app-v2/      
│   ├── Dockerfile
│   ├── .dockerignore
│   └── terraform/
│       └── backend/
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars
│       ├── outputs.tf
│
├── express-t2s-app-v3/      
│   ├── .github/workflows/ci.yml
│   └── terraform/
│       └── backend/
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars
│       ├── outputs.tf
│
├── express-t2s-app-v4/      # Coming Out Soon
│   └── terraform/
│       └── backend/
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars
│       ├── outputs.tf
│       ├── backend.tf
│
├── express-t2s-app-v5/      # Coming Out Soon
│   └── terraform/
│       └── backend/
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars
│       ├── outputs.tf
│       ├── backend.tf
│
├── express-t2s-app-v6/      # Coming Out Soon - AI Enhanced
│   └── terraform/
│       └── backend/
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars
│       ├── outputs.tf
│       ├── backend.tf
│
├── .gitignore
└── README.md
```

---

## Remote Backend Setup

To securely manage state files per version, we use **Terraform remote backends (S3 + DynamoDB)**. Each version has its own isolated backend for collaborative provisioning.

### Steps:

1. Manually create:
   - S3 bucket: `t2s-terraform-state`
   - DynamoDB table: `t2s-terraform-lock`
   - You define your variables on the terraform.tfvars file

2. Add the following to `terraform/backend/backend.tf` for each version:

```hcl
terraform {
  backend "s3" {
    bucket         = "t2s-terraform-state"
    key            = "express-t2s-app/<version>/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "t2s-terraform-lock"
    encrypt        = true
  }
}
```

3. Initialize and Deploy backend:

```bash
cd express-t2s-app-v<version>/terraform/backend
terraform init
terraform plan
terraform apply
```

4. Initialize and Deploy the Infrastructure:
- Configure the terraform.tfvars file
- Initialize and deploy the Infra using the following commands

```bash
cd ..         # To move up (one level) to this location, express-t2s-app-v<version>/terraform
terraform init
terraform plan
terraform apply
```

---

## Outcome

By the end of this entire project (versions 1 through 6), you will have:
- Fully provisioned infrastructure via Terraform
- Modular stateful deployments
- GitHub Actions CI/CD
- Secure, observable, AI-enabled environments
- Scalable mentorship onboarding platform

---

© 2025 Emmanuel Naweji. All rights reserved.
