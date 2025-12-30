# t2s-iam-oidc-foundation (ECS + EKS + Terraform Backend) — GitHub OIDC Setup

This repo creates a production-style GitHub Actions → AWS authentication foundation using OIDC (no long-lived AWS access keys).

Supports:
- Terraform backend provisioning (S3 + DynamoDB)
- ECR (build/push images)
- ECS (deploy services)
- EKS (provision or deploy to Kubernetes)

---

## Why OIDC (best practice)
Instead of storing AWS access keys in GitHub, GitHub Actions requests short-lived credentials from AWS using OIDC.
- No static keys to leak
- Short session duration
- Auditable
- Restrictable by repo + branch

---

## Quick Start

### Step 1) Create the GitHub OIDC provider (once per AWS account)
```bash
bash 00-oidc-provider/create_oidc_provider.sh
```

### Step 2) Create least-privilege roles
ECS pipeline role:
```bash
bash 01-roles/create_role_least_privilege_ecs.sh
```

EKS pipeline role:
```bash
bash 01-roles/create_role_least_privilege_eks.sh
```

Optional (temporary) admin bootstrap role (break-glass):
```bash
bash 01-roles/create_role_admin_bootstrap.sh
```

Delete the admin bootstrap role after setup:
```bash
bash 01-roles/delete_role_admin_bootstrap.sh <ROLE_NAME>
```

---

## Required environment variables
Set these before running scripts:

```bash
export AWS_REGION="us-east-1"
export AWS_ACCOUNT_ID="123456789012"
export GITHUB_ORG="Here2ServeU"
export GITHUB_REPO="express-t2s-collection"
export GITHUB_BRANCH="main"
```

---

## GitHub Actions snippets
- ECS: 03-github-actions-snippets/oidc-config-ecs.yml
- EKS: 03-github-actions-snippets/oidc-config-eks.yml

---

## Production hardening
See: 04-production-hardening/PRODUCTION_HARDENING.md
