#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"

if [[ -z "${AWS_ACCOUNT_ID:-}" || -z "${GITHUB_ORG:-}" || -z "${GITHUB_REPO:-}" || -z "${GITHUB_BRANCH:-}" ]]; then
  echo "ERROR: Missing required env vars."
  echo "Set: AWS_ACCOUNT_ID, GITHUB_ORG, GITHUB_REPO, GITHUB_BRANCH"
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TRUST_TEMPLATE="${ROOT_DIR}/01-roles/trust-policy.json.template"

render_trust() {
  local out="$1"
  sed     -e "s/{{AWS_ACCOUNT_ID}}/${AWS_ACCOUNT_ID}/g"     -e "s/{{GITHUB_ORG}}/${GITHUB_ORG}/g"     -e "s/{{GITHUB_REPO}}/${GITHUB_REPO}/g"     -e "s/{{GITHUB_BRANCH}}/${GITHUB_BRANCH}/g"     "${TRUST_TEMPLATE}" > "${out}"
}

create_role_if_missing() {
  local role_name="$1"
  local trust_file="$2"

  if aws iam get-role --role-name "${role_name}" >/dev/null 2>&1; then
    echo "Role exists: ${role_name}"
  else
    echo "Creating role: ${role_name}"
    aws iam create-role       --role-name "${role_name}"       --assume-role-policy-document "file://${trust_file}"       --max-session-duration 3600       --tags Key=Project,Value=T2S Key=Purpose,Value=GitHubOIDC
  fi
}

put_inline_policy() {
  local role_name="$1"
  local policy_name="$2"
  local policy_file="$3"
  echo "Attaching inline policy ${policy_name} to ${role_name}"
  aws iam put-role-policy     --role-name "${role_name}"     --policy-name "${policy_name}"     --policy-document "file://${policy_file}"
}

echo "Repo restriction: ${GITHUB_ORG}/${GITHUB_REPO} branch=${GITHUB_BRANCH}"

POLICY_FILE="${ROOT_DIR}/02-policies/least-priv-eks-ecr-terraform.json"
POLICY_NAME="t2s-least-priv-eks-ecr-terraform"

for ENV in dev staging prod; do
  ROLE_NAME="t2s-gha-eks-deploy-${ENV}"
  TRUST_FILE="/tmp/${ROLE_NAME}-trust.json"
  render_trust "${TRUST_FILE}"
  create_role_if_missing "${ROLE_NAME}" "${TRUST_FILE}"
  put_inline_policy "${ROLE_NAME}" "${POLICY_NAME}" "${POLICY_FILE}"
done

echo "Done."
