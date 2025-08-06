# Express T2S App Monorepo

## Overview

This repository is the monorepo for the evolving Express-based web applications that support the mission of **Transformed 2 Succeed (T2S)**. Each version (`v1`, `v2`, etc.) represents a progressive stage of the Node.js + Express app from MVP to a production-ready, cloud-native, DevOps-enabled platform.

Our long-term vision is to build a mentorship system that is:
- Containerized using Docker
- Deployed via Terraform on AWS (ECR, ECS, EKS)
- Monitored and observable
- Secured with IAM, WAF, and DevSecOps scanning
- Scalable, cost-efficient, and highly available

---

## Goals

- Containerize each app version using Docker
- Push container images to AWS ECR
- Deploy using Terraform with ECS and EKS
- Implement GitHub Actions for CI/CD
- Add observability and monitoring (Grafana, Prometheus, CloudWatch)
- Integrate DevSecOps (Trivy, Checkov)
- Enable secure, automated mentorship workflows

---

## Versions and Status

Each app version is built on DevOps principles and infrastructure-as-code:

- `express-t2s-app-v1`: Basic Node.js + Express app
- `express-t2s-app-v2`: Adds Docker support and CI pipeline structure
- `express-t2s-app-v3`: Includes GitHub Actions and AWS ECR deployment
- `express-t2s-app-v4`: Adds ECS Fargate and Terraform infrastructure (Coming Out Soon)
- `express-t2s-app-v5`: Adds EKS with ArgoCD, observability stack (Coming Out Soon)
- `express-t2s-app-v6`: Adds AI-based automation and intelligent monitoring (Coming Out Soon)

---

## Repo Structure

```
express-t2s-app/
├── express-t2s-app-v1/
│   ├── public/
│   └── index.js
│
├── express-t2s-app-v2/
│   ├── Dockerfile
│   └── .dockerignore
│
├── express-t2s-app-v3/
│   └── .github/workflows/ci.yml
│
├── express-t2s-app-v4/
│   ├── terraform/
│   │   ├── backend/
│   │   │   └── backend.tf
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── ...
│
├── express-t2s-app-v5/
│   ├── terraform/
│   │   ├── backend/
│   │   │   └── backend.tf
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── ...
│
├── express-t2s-app-v6/
│   ├── terraform/
│   │   ├── backend/
│   │   │   └── backend.tf
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── ...
│
└── README.md
```

---

## Remote Backend Setup

To enable collaborative and secure Terraform state management, each version uses an **S3 backend with DynamoDB locking**:

1. Manually create or bootstrap:
   - S3 bucket: `t2s-terraform-state`
   - DynamoDB table: `t2s-terraform-lock`

2. Add this to `terraform/backend/backend.tf` for the version:

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

3. Initialize Terraform backend:

```bash
cd terraform/backend
terraform init
```

---

## Local App Test (v1)

```bash
cd express-t2s-app-v1
npm install
node index.js
```

Visit: `http://localhost:3000`

---

## Cloud Deployment (v4+)

1. Ensure Docker image is built and pushed to ECR.
```bash
chmod +x build_and_push.sh
./build_and_push.sh
```

3. Navigate to the Terraform directory of the version:

```bash
cd express-t2s-app-v4/terraform
cd /ecr (or /ecs or eks)
```

3. Apply the Terraform deployment:

```bash
terraform init
terraform apply
```

4. Access the application using the output `load_balancer_dns` or domain name (ecs/eks).

---
## Clean Up
```bash
# Deleting the Backend
cd ..                                        #To move up to express-t2s-app-v4/terraform
aws s3 rm s3://emmanuel-tf-state --recursive #To clean bucket via script (non-versioned only)
terraform destroy --auto-approve
```

- When using versioning, create a file and name it, delete_all_versions.py
- Add the following content ensuring you use your Bucket name:
```py
import boto3

bucket_name = "emmanuel-tf-state"
s3 = boto3.client("s3")

versions = s3.list_object_versions(Bucket=bucket_name)

for item in versions.get('Versions', []) + versions.get('DeleteMarkers', []):
    print(f"Deleting {item['Key']} (version: {item['VersionId']})")
    s3.delete_object(Bucket=bucket_name, Key=item['Key'], VersionId=item['VersionId'])
```

# Deleting the other Resources
cd ecr (or ecs/eks)
terraform destroy --auto-approve
```

---

## Final Outcome

By completing this monorepo series, we will achieve:
- Production-grade cloud infrastructure
- CI/CD & GitOps workflows
- Secure, observable applications
- Real-world DevOps portfolio experience

---

© 2025 Emmanuel Naweji. All rights reserved.
