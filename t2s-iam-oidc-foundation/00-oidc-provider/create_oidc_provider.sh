#!/usr/bin/env bash
set -euo pipefail

# Creates the GitHub OIDC provider in AWS (one time per AWS account).
# Requires: AWS CLI configured with permissions to manage IAM.

: "${AWS_ACCOUNT_ID:?Set AWS_ACCOUNT_ID}"
: "${AWS_REGION:?Set AWS_REGION}"

PROVIDER_URL="token.actions.githubusercontent.com"
AUDIENCE="sts.amazonaws.com"

# GitHub Actions OIDC root CA thumbprint (commonly used).
# If AWS changes certificate chains in the future, re-check and update.
THUMBPRINT="6938fd4d98bab03faadb97b34396831e3780aea1"

echo "Checking for existing OIDC provider..."
EXISTING_ARN=$(aws iam list-open-id-connect-providers   --query "OpenIDConnectProviderList[?contains(Arn, ':oidc-provider/${PROVIDER_URL}')].Arn | [0]"   --output text 2>/dev/null || true)

if [[ "${EXISTING_ARN}" != "None" && -n "${EXISTING_ARN}" ]]; then
  echo "OIDC provider already exists: ${EXISTING_ARN}"
  exit 0
fi

echo "Creating OIDC provider for ${PROVIDER_URL}..."
aws iam create-open-id-connect-provider   --url "https://${PROVIDER_URL}"   --client-id-list "${AUDIENCE}"   --thumbprint-list "${THUMBPRINT}" >/dev/null

NEW_ARN=$(aws iam list-open-id-connect-providers   --query "OpenIDConnectProviderList[?contains(Arn, ':oidc-provider/${PROVIDER_URL}')].Arn | [0]"   --output text)

echo "Created OIDC provider: ${NEW_ARN}"
