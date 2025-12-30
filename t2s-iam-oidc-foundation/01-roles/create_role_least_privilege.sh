#!/usr/bin/env bash
set -euo pipefail

# Creates least-privilege GitHub OIDC roles for dev/staging/prod.
# Attaches inline policies from 02-policies/.
#
# Required env vars:
#   AWS_ACCOUNT_ID, AWS_REGION, GITHUB_ORG, GITHUB_REPO
#   DEV_BRANCH, STAGING_BRANCH, PROD_BRANCH
#   ECR_REPOS, TF_STATE_BUCKET, TF_LOCK_TABLE
#
# Optional:
#   WORKFLOW_REF (recommended for prod hardening; used in hardening doc only)

: "${AWS_ACCOUNT_ID:?Set AWS_ACCOUNT_ID}"
: "${AWS_REGION:?Set AWS_REGION}"
: "${GITHUB_ORG:?Set GITHUB_ORG}"
: "${GITHUB_REPO:?Set GITHUB_REPO}"
: "${DEV_BRANCH:?Set DEV_BRANCH}"
: "${STAGING_BRANCH:?Set STAGING_BRANCH}"
: "${PROD_BRANCH:?Set PROD_BRANCH}"
: "${ECR_REPOS:?Set ECR_REPOS}"
: "${TF_STATE_BUCKET:?Set TF_STATE_BUCKET}"
: "${TF_LOCK_TABLE:?Set TF_LOCK_TABLE}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TRUST_TEMPLATE="${ROOT_DIR}/01-roles/trust-policy.json.template"

create_role() {
  local role_name="$1"
  local branch="$2"
  local policy_file="$3"

  echo "----"
  echo "Creating/updating role: ${role_name} (branch: ${branch})"

  export GITHUB_BRANCH="${branch}"
  envsubst < "${TRUST_TEMPLATE}" > /tmp/trust.json

  if aws iam get-role --role-name "${role_name}" >/dev/null 2>&1; then
    echo "Role exists. Updating trust policy..."
    aws iam update-assume-role-policy --role-name "${role_name}" --policy-document file:///tmp/trust.json >/dev/null
  else
    echo "Role does not exist. Creating role..."
    aws iam create-role       --role-name "${role_name}"       --assume-role-policy-document file:///tmp/trust.json       --description "T2S GitHub Actions OIDC deploy role (${role_name})" >/dev/null
  fi

  echo "Attaching inline policy from: ${policy_file}"
  # Render policy with variables so you can scope to your account, region, repos, and terraform backend.
  envsubst < "${policy_file}" > /tmp/policy.json
  aws iam put-role-policy     --role-name "${role_name}"     --policy-name "t2s-least-priv-${role_name}"     --policy-document file:///tmp/policy.json >/dev/null

  local arn
  arn=$(aws iam get-role --role-name "${role_name}" --query "Role.Arn" --output text)
  echo "Role ARN: ${arn}"
}

POLICY_ECS_ECR_TF="${ROOT_DIR}/02-policies/least-priv-ecs-ecr-terraform.json"
POLICY_EKS="${ROOT_DIR}/02-policies/least-priv-eks.json"

# Dev/staging typically deploy to ECS + ECR + Terraform backend
create_role "t2s-gha-deploy-dev" "${DEV_BRANCH}" "${POLICY_ECS_ECR_TF}"
create_role "t2s-gha-deploy-staging" "${STAGING_BRANCH}" "${POLICY_ECS_ECR_TF}"

# Prod might deploy to ECS/EKS/ECR + Terraform backend; choose based on your target.
# Here we attach the EKS policy (which includes ECR + TF backend too).
create_role "t2s-gha-deploy-prod" "${PROD_BRANCH}" "${POLICY_EKS}"

echo "----"
echo "Done. Copy the Role ARN into your GitHub repo secret AWS_ROLE_TO_ASSUME (per environment)."
echo "Region secret: AWS_REGION=${AWS_REGION}"
