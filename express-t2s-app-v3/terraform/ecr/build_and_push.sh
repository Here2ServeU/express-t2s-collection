#!/usr/bin/env sh
set -eu

# -------- Config --------
AWS_REGION="${AWS_REGION:-us-east-1}"
REPO_NAME="${REPO_NAME:-express-t2s-app-repo}"
APP_DIR="${APP_DIR:-$(cd "$(dirname "$0")"/../../app && pwd)}"
PLATFORM="${PLATFORM:-linux/amd64}"
TAG="latest"

# Optional positional args
[ "${1:-}" ] && AWS_REGION="$1"
[ "${2:-}" ] && REPO_NAME="$2"

# -------- Resolve ECR --------
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
ECR_DOMAIN="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
ECR_URI="${ECR_DOMAIN}/${REPO_NAME}"

# -------- Ensure Repo Exists (No Deletion Logic) --------
echo "Checking if repository $REPO_NAME exists in $AWS_REGION..."
if ! aws ecr describe-repositories --repository-names "$REPO_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
  echo "Repository not found. Creating: ${REPO_NAME}"
  aws ecr create-repository \
    --repository-name "$REPO_NAME" \
    --region "$AWS_REGION" \
    --image-scanning-configuration scanOnPush=true \
    --encryption-configuration encryptionType=AES256
else
  echo "Repository already exists. Proceeding..."
fi

# -------- Login & Push --------
echo "Logging in to ECR..."
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_DOMAIN"

echo "Building and pushing $ECR_URI:$TAG"
docker buildx create --use >/dev/null 2>&1 || true
docker buildx build --platform "$PLATFORM" -t "$ECR_URI:$TAG" --push "$APP_DIR"

echo "Pushed: $ECR_URI:$TAG"
