#!/usr/bin/env bash
set -euo pipefail

# Creates an admin bootstrap GitHub OIDC role.
# Use only temporarily for initial platform provisioning, then disable or delete.
#
# Required env vars:
#   AWS_ACCOUNT_ID, AWS_REGION, GITHUB_ORG, GITHUB_REPO, PROD_BRANCH

: "${AWS_ACCOUNT_ID:?Set AWS_ACCOUNT_ID}"
: "${AWS_REGION:?Set AWS_REGION}"
: "${GITHUB_ORG:?Set GITHUB_ORG}"
: "${GITHUB_REPO:?Set GITHUB_REPO}"
: "${PROD_BRANCH:?Set PROD_BRANCH}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TRUST_TEMPLATE="${ROOT_DIR}/01-roles/trust-policy.json.template"

ROLE_NAME="t2s-gha-admin-bootstrap"
export GITHUB_BRANCH="${PROD_BRANCH}"
envsubst < "${TRUST_TEMPLATE}" > /tmp/trust.json

if aws iam get-role --role-name "${ROLE_NAME}" >/dev/null 2>&1; then
  echo "Role exists. Updating trust policy..."
  aws iam update-assume-role-policy --role-name "${ROLE_NAME}" --policy-document file:///tmp/trust.json >/dev/null
else
  echo "Creating admin bootstrap role..."
  aws iam create-role     --role-name "${ROLE_NAME}"     --assume-role-policy-document file:///tmp/trust.json     --description "T2S GitHub Actions OIDC admin bootstrap role (temporary)" >/dev/null
fi

echo "Attaching AWS managed AdministratorAccess policy (break-glass)."
aws iam attach-role-policy   --role-name "${ROLE_NAME}"   --policy-arn "arn:aws:iam::aws:policy/AdministratorAccess" >/dev/null

ARN=$(aws iam get-role --role-name "${ROLE_NAME}" --query "Role.Arn" --output text)
echo "Role ARN: ${ARN}"
echo "Important: remove this role after bootstrap or restrict it heavily."
