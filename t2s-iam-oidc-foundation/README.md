# T2S IAM OIDC Foundation (GitHub Actions → AWS)

This repository creates the **AWS IAM OIDC provider** and **IAM roles** used by GitHub Actions to deploy your apps **without storing long‑lived AWS keys**.

## What this repo gives you

- GitHub OIDC Provider in AWS (`token.actions.githubusercontent.com`)
- Three deployment roles (recommended):
  - `t2s-gha-deploy-dev`
  - `t2s-gha-deploy-staging`
  - `t2s-gha-deploy-prod`
- Two role flavors:
  - **Least privilege** (recommended for normal use)
  - **Admin bootstrap** (only for initial setup / break-glass, then disable)

It also includes ready-to-copy **GitHub Actions snippets** and a **production hardening** checklist.

---

## Prerequisites (your machine)

- AWS CLI v2 installed and configured (short-lived credentials recommended, e.g., SSO)
- Permissions to create IAM resources in the target AWS account (for initial bootstrap only)

---

## 1) Set your variables (required)

Run these in your terminal before executing scripts:

```bash
export AWS_REGION="us-east-1"
export AWS_ACCOUNT_ID="123456789012"

# The GitHub org/user that owns the repo that will assume this role
export GITHUB_ORG="Here2ServeU"

# The specific application repo that will deploy (example: express-t2s-collection/express-t2s-app-v3 is typically a separate repo like express-t2s-app-v3)
export GITHUB_REPO="express-t2s-app-v3"

# Branch restrictions (recommended)
export DEV_BRANCH="dev"
export STAGING_BRANCH="staging"
export PROD_BRANCH="main"

# ECR repositories this role can push to (comma-separated, no spaces)
export ECR_REPOS="express-t2s-app-repo"

# Terraform state backend (if used)
export TF_STATE_BUCKET="t2s-terraform-state-123456789012"
export TF_LOCK_TABLE="t2s-terraform-locks"

# Optional: restrict to a specific workflow file (strongly recommended for prod)
# Format: owner/repo/.github/workflows/workflow.yml@ref
export WORKFLOW_REF="Here2ServeU/express-t2s-app-v3/.github/workflows/cicd.yml@refs/heads/main"
```

---

## 2) Create the GitHub OIDC provider (one time per AWS account)

```bash
bash 00-oidc-provider/create_oidc_provider.sh
```

---

## 3) Create least-privilege deploy roles (dev/staging/prod)

```bash
bash 01-roles/create_role_least_privilege.sh
```

This creates roles with trust policies restricted to:
- Your GitHub org + repo
- Specific branch per environment (dev/staging/prod)
- Audience `sts.amazonaws.com`

---

## 4) (Optional) Create an admin bootstrap role (break-glass)

Use only during initial setup, then disable or delete.

```bash
bash 01-roles/create_role_admin_bootstrap.sh
```

---

## 5) Configure your app repository to assume the role

In your **application repo** (e.g., `express-t2s-app-v3`), your workflow should include:

- `permissions: id-token: write`
- `aws-actions/configure-aws-credentials@v4` with `role-to-assume`

Copy the example from:
- `03-github-actions-snippets/oidc-config.yml`

---

## Recommended GitHub Secrets (app repo)

Store these in the **app repo** (Settings → Secrets and variables → Actions):

- `AWS_REGION` (example: `us-east-1`)
- `AWS_ROLE_TO_ASSUME` (Role ARN output by the script, for the correct environment)

No AWS access keys are required.

---

## Production hardening (read this)

See:
- `04-production-hardening/PRODUCTION_HARDENING.md`

---

## Notes for teaching beginners

- Teach manual AWS provisioning first (Version 3 Part 1).
- Teach OIDC second (Version 3 Part 2) as “secure automation without secret keys”.
- Keep OIDC in this foundation repo; keep deploy scripts inside each app repo.

