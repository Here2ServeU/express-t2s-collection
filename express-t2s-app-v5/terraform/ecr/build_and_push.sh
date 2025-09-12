#!/usr/bin/env sh
set -eu

# -------- Config (env or args) --------
AWS_REGION="${AWS_REGION:-us-east-1}"
REPO_NAME="${REPO_NAME:-t2s-express-app}"
APP_DIR="${APP_DIR:-$(cd "$(dirname "$0")"/../../app && pwd)}"
PLATFORM="${PLATFORM:-linux/amd64}"   # single platform only
TAG="latest"                          # always latest

# Optional positional args: REGION REPO_NAME
[ "${1:-}" ] && AWS_REGION="$1"
[ "${2:-}" ] && REPO_NAME="$2"

# -------- Checks --------
command -v aws >/dev/null 2>&1 || { echo "aws CLI not found"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "docker not found"; exit 1; }
[ -d "$APP_DIR" ] || { echo "APP_DIR not found: $APP_DIR"; exit 1; }

# -------- Resolve account/ECR --------
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
ECR_DOMAIN="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
ECR_URI="${ECR_DOMAIN}/${REPO_NAME}"

echo "Account:  $ACCOUNT_ID"
echo "Region:   $AWS_REGION"
echo "Repo:     $ECR_URI"
echo "Platform: $PLATFORM"
echo "Tag:      $TAG"
echo "App dir:  $APP_DIR"

# -------- Ensure repo --------
if ! aws ecr describe-repositories --repository-names "$REPO_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
  echo "Creating ECR repository: ${REPO_NAME}"
  aws ecr create-repository --repository-name "$REPO_NAME" --region "$AWS_REGION" >/dev/null
fi

# -------- Login --------
echo "Logging in to ECR"
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_DOMAIN"

# -------- Build & push --------
echo "Building and pushing $ECR_URI:$TAG"
docker buildx create --use >/dev/null 2>&1 || true
docker buildx build \
  --platform "$PLATFORM" \
  -t "$ECR_URI:$TAG" \
  --push "$APP_DIR"

echo "Pushed: $ECR_URI:$TAG"

# -------- Tips --------
echo
echo "Next steps:"
echo "  kubectl -n apps set image deploy/express-t2s app=$ECR_URI:$TAG"
echo "  kubectl -n apps rollout status deploy/express-t2s"
