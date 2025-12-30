# t2s-iam-oidc-foundation  
## (ECS + EKS + Terraform Backend) — GitHub OIDC Setup

This repository creates a **production-style GitHub Actions → AWS authentication foundation** using **OIDC (OpenID Connect)**.  
It removes the need for long‑lived AWS access keys and replaces them with **short‑lived, least‑privilege credentials**.

---

## What This Repository Supports

- Terraform backend provisioning (S3 + DynamoDB)
- Amazon ECR (Docker image build & push)
- Amazon ECS (container service deployments)
- Amazon EKS (Kubernetes cluster provisioning and workload deployments)

---

## Why OIDC (Best Practice)

Instead of storing AWS access keys in GitHub, GitHub Actions requests **temporary credentials** from AWS using OIDC.

Benefits:
- No static keys to leak
- Short‑lived sessions
- Fully auditable via AWS CloudTrail
- Access restricted by GitHub org, repository, and branch
- Aligns with enterprise and regulated‑industry standards

This is the same pattern used by large enterprises and security‑focused DevOps teams.

---

## Repository Structure

```
t2s-iam-oidc-foundation/
├── README.md
├── 00-oidc-provider/
│   └── create_oidc_provider.sh
├── 01-roles/
│   ├── create_role_least_privilege_ecs.sh
│   ├── create_role_least_privilege_eks.sh
│   ├── create_role_admin_bootstrap.sh
│   └── delete_role_admin_bootstrap.sh
├── 02-policies/
│   ├── least-priv-ecs-ecr-terraform.json
│   ├── least-priv-eks.json
│   └── admin.json
├── 03-github-actions-snippets/
│   ├── oidc-config-ecs.yml
│   └── oidc-config-eks.yml
└── 04-production-hardening/
    └── PRODUCTION_HARDENING.md
```

---

## Folder Breakdown (Beginner‑Friendly)

### 00‑oidc‑provider
Creates the **GitHub OIDC Identity Provider** in AWS.

- This establishes trust between AWS and GitHub
- Run **once per AWS account**
- Required before roles can be assumed

Usage:
```bash
bash 00-oidc-provider/create_oidc_provider.sh
```

---

### 01‑roles
Creates IAM roles that GitHub Actions can assume.

Roles included:
- **Least‑privilege ECS role** – deploy containers and push images
- **Least‑privilege EKS role** – deploy Kubernetes workloads
- **Admin bootstrap role** – temporary break‑glass role for initial setup only

Usage:
```bash
bash 01-roles/create_role_least_privilege_ecs.sh
bash 01-roles/create_role_least_privilege_eks.sh
```

Optional admin role:
```bash
bash 01-roles/create_role_admin_bootstrap.sh
```

Delete admin role after setup:
```bash
bash 01-roles/delete_role_admin_bootstrap.sh <ROLE_NAME>
```

---

### 02‑policies
Contains IAM policy JSON files defining **exact permissions**.

- ECS + ECR + Terraform backend policy
- EKS‑specific policy
- Admin policy (bootstrap only)

These enforce least‑privilege access.

---

### 03‑github‑actions‑snippets
Reusable GitHub Actions YAML snippets.

- ECS OIDC configuration
- EKS OIDC configuration

Copy these into your CI/CD workflows.

---

### 04‑production‑hardening
Security best practices for real environments:
- Role isolation per environment
- Session duration limits
- Branch protection
- Audit strategies

---

## Required Environment Variables

Set these before running scripts:

```bash
export AWS_REGION="us-east-1"
export AWS_ACCOUNT_ID="123456789012"
export GITHUB_ORG="Here2ServeU"
export GITHUB_REPO="express-t2s-collection"
export GITHUB_BRANCH="main"
```

---

## Quick Start

### Step 1) Create the GitHub OIDC Provider
```bash
bash 00-oidc-provider/create_oidc_provider.sh
```

### Step 2) Create Least‑Privilege Roles
```bash
bash 01-roles/create_role_least_privilege_ecs.sh
bash 01-roles/create_role_least_privilege_eks.sh
```

### Step 3) (Optional) Bootstrap Admin Role
```bash
bash 01-roles/create_role_admin_bootstrap.sh
```

Delete when finished:
```bash
bash 01-roles/delete_role_admin_bootstrap.sh <ROLE_NAME>
```

---

## GitHub Actions Usage

Use the provided snippets:

- ECS: `03-github-actions-snippets/oidc-config-ecs.yml`
- EKS: `03-github-actions-snippets/oidc-config-eks.yml`

These configure GitHub Actions to assume IAM roles via OIDC.

---

## Architecture Overview

GitHub Actions  
→ GitHub OIDC Token  
→ AWS IAM OIDC Provider  
→ IAM Role (Least Privilege)  
→ AWS Services (S3, DynamoDB, ECR, ECS, EKS)

---

Built by **Emmanuel Naweji**
Secure. Auditable. Production‑Ready.
