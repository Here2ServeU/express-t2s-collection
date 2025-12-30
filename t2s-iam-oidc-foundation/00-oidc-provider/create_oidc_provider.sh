#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"

echo "Using AWS_REGION=${AWS_REGION}"
echo "Checking if OIDC provider already exists..."

EXISTING=$(aws iam list-open-id-connect-providers --query "OpenIDConnectProviderList[].Arn" --output text | tr '\t' '\n' | grep -E "token\.actions\.githubusercontent\.com" || true)

if [[ -n "${EXISTING}" ]]; then
  echo "OIDC provider already exists: ${EXISTING}"
  exit 0
fi

echo "Creating GitHub OIDC provider..."
aws iam create-open-id-connect-provider \
  --url "https://token.actions.githubusercontent.com" \
  --client-id-list "sts.amazonaws.com" \
  --thumbprint-list "6938fd4d98bab03faadb97b34396831e3780aea1"

echo "Done."
