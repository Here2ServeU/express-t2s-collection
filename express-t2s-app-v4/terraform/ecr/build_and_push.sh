#!/usr/bin/env sh
set -eu

# -------- Config (override via env or args) --------
AWS_REGION="${AWS_REGION:-us-east-1}"
REPO_NAME="${REPO_NAME:-t2s-express-app}"
APP_DIR="${APP_DIR:-$(cd "$(dirname "$0")"/../../app && pwd)}"
PLATFORMS="${PLATFORMS:-linux/amd64}"  # change to "linux/amd64,linux/arm64" for multi-arch
TAG="${TAG:-$(date +%Y%m%d%H%M%S)}"

# Optional positional args: REGION REPO_NAME TAG
if [ "${1:-}" != "" ]; then AWS_REGION="$1"; fi
if [ "${2:-}" != "" ]; then REPO_NAME="$2"; fi
if [ "${3:-}" != "" ]; then TAG="$3"; fi

# -------- Checks --------
if [ ! -d "$APP_DIR" ]; then
  echo "Error: APP_DIR not found: $APP_DIR"
  exit 1
fi

if ! command -v aws >/dev/null 2>&1; then
  echo "Error: aws CLI not found."
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker not found."
  exit 1
fi

# -------- Resolve account and ECR --------
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
ECR_DOMAIN="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
ECR_URI="${ECR_DOMAIN}/${REPO_NAME}"

echo "Account:  ${ACCOUNT_ID}"
echo "Region:   ${AWS_REGION}"
echo "Repo:     ${ECR_URI}"
echo "Platform: ${PLATFORMS}"
echo "Tag:      ${TAG}"
echo "App dir:  ${APP_DIR}"

# -------- Ensure ECR repo --------
if ! aws ecr describe-repositories --repository-names "$REPO_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
  echo "Creating ECR repository: ${REPO_NAME}"
  aws ecr create-repository --repository-name "$REPO_NAME" --region "$AWS_REGION" >/dev/null
fi

# -------- Login to ECR --------
echo "Logging in to ECR"
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_DOMAIN"

# -------- Buildx builder --------
# Safe to ignore error if builder already exists
docker buildx create --use >/dev/null 2>&1 || true

# -------- Build & Push --------
echo "Building and pushing image(s)"
docker buildx build \
  --platform "$PLATFORMS" \
  -t "$ECR_URI:$TAG" \
  -t "$ECR_URI:latest" \
  --push "$APP_DIR"

echo "Pushed:"
echo "  $ECR_URI:$TAG"
echo "  $ECR_URI:latest"

echo "Next:"
echo "  kubectl -n apps set image deploy/express-t2s app=$ECR_URI:$TAG"
echo "  kubectl -n apps rollout status deploy/express-t2s"
