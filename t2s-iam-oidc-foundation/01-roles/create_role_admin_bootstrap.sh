#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
ROLE_NAME="${ROLE_NAME:-t2s-gha-admin-bootstrap}"

if [[ -z "${AWS_ACCOUNT_ID:-}" || -z "${GITHUB_ORG:-}" || -z "${GITHUB_REPO:-}" || -z "${GITHUB_BRANCH:-}" ]]; then
  echo "ERROR: Missing required env vars."
  echo "Set: AWS_ACCOUNT_ID, GITHUB_ORG, GITHUB_REPO, GITHUB_BRANCH"
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TRUST_TEMPLATE="${ROOT_DIR}/01-roles/trust-policy.json.template"
TRUST_FILE="/tmp/${ROLE_NAME}-trust.json"

sed   -e "s/{{AWS_ACCOUNT_ID}}/${AWS_ACCOUNT_ID}/g"   -e "s/{{GITHUB_ORG}}/${GITHUB_ORG}/g"   -e "s/{{GITHUB_REPO}}/${GITHUB_REPO}/g"   -e "s/{{GITHUB_BRANCH}}/${GITHUB_BRANCH}/g"   "${TRUST_TEMPLATE}" > "${TRUST_FILE}"

if aws iam get-role --role-name "${ROLE_NAME}" >/dev/null 2>&1; then
  echo "Role exists: ${ROLE_NAME}"
else
  echo "Creating admin bootstrap role: ${ROLE_NAME}"
  aws iam create-role     --role-name "${ROLE_NAME}"     --assume-role-policy-document "file://${TRUST_FILE}"     --max-session-duration 3600     --tags Key=Project,Value=T2S Key=Purpose,Value=AdminBootstrap
fi

echo "Attaching AdministratorAccess..."
aws iam attach-role-policy   --role-name "${ROLE_NAME}"   --policy-arn "arn:aws:iam::aws:policy/AdministratorAccess"

echo "Done. Delete after setup:"
echo "bash 01-roles/delete_role_admin_bootstrap.sh ${ROLE_NAME}"
