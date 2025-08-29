#!/usr/bin/env bash
set -euo pipefail

REGION="${REGION:-us-east-1}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

# Read from Terraform outputs (alternative: pass via env)
REPO_URL="$(terraform output -raw repository_url 2>/dev/null || true)"
ACCOUNT_ID="$(terraform output -raw account_id 2>/dev/null || true)"

if [[ -z "${REPO_URL}" || -z "${ACCOUNT_ID}" ]]; then
  echo "Reading outputs via terraform failed; falling back to aws cli lookups."
  if [[ -z "${REPO_NAME:-}" ]]; then
    echo "Set REPO_NAME env var or run from terraform and ensure outputs are available."
    exit 1
  fi
  REPO_URL="$(aws ecr describe-repositories --repository-names "${REPO_NAME}" --region "${REGION}" \
              --query 'repositories[0].repositoryUri' --output text)"
  ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
fi

echo "Repo URL: ${REPO_URL}"
aws ecr get-login-password --region "${REGION}" \
| docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

# Build, tag, push
docker build -t app:${IMAGE_TAG} .
docker tag app:${IMAGE_TAG} "${REPO_URL}:${IMAGE_TAG}"
docker push "${REPO_URL}:${IMAGE_TAG}"

echo "Pushed: ${REPO_URL}:${IMAGE_TAG}"
