#!/usr/bin/env sh
set -eu

###############################################
# Multi-Image Builder for:
#   1. Express Web App  (Node.js)
#   2. AIOps API        (FastAPI/Python)
#
# Uses SAME build + push workflow for both images.
###############################################

AWS_REGION="${AWS_REGION:-us-east-1}"
PLATFORM="${PLATFORM:-linux/amd64}"   # EKS nodes are amd64
TAG="latest"

# FOLDERS
EXPRESS_DIR="${EXPRESS_DIR:-$(cd "$(dirname "$0")"/../../app && pwd)}"
AIOPS_DIR="${AIOPS_DIR:-$(cd "$(dirname "$0")"/../../aiops-service && pwd)}"

# REPO NAMES
EXPRESS_REPO="${EXPRESS_REPO:-t2s-express-app}"
AIOPS_REPO="${AIOPS_REPO:-aiops-api}"

# Optional overrides
[ "${1:-}" ] && AWS_REGION="$1"

# ---- Checks ----
command -v aws >/dev/null || { echo "aws CLI missing"; exit 1; }
command -v docker >/dev/null || { echo "docker missing"; exit 1; }

[ -d "$EXPRESS_DIR" ] || { echo "Express directory not found: $EXPRESS_DIR"; exit 1; }
[ -d "$AIOPS_DIR" ]   || { echo "AIOps directory not found: $AIOPS_DIR"; exit 1; }

# ---- AWS Account ----
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
ECR="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "=============================================="
echo "   MULTI-IMAGE BUILD & PUSH TO AWS ECR"
echo "=============================================="
echo "AWS Account:  $ACCOUNT_ID"
echo "Region:       $AWS_REGION"
echo "Platform:     $PLATFORM"
echo

# ---- Ensure ECR repositories ----
ensure_repo() {
  REPO="$1"
  if ! aws ecr describe-repositories --repository-names "$REPO" --region "$AWS_REGION" >/dev/null 2>&1; then
    echo "Creating ECR repo: $REPO"
    aws ecr create-repository --repository-name "$REPO" --region "$AWS_REGION" >/dev/null
  else
    echo "Repo exists: $REPO"
  fi
}

ensure_repo "$EXPRESS_REPO"
ensure_repo "$AIOPS_REPO"

# ---- Login ----
echo "Logging in to ECR..."
aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "$ECR"

# Enable buildx
docker buildx create --use >/dev/null 2>&1 || true

###############################################
# 1) BUILD & PUSH EXPRESS WEB APP
###############################################
echo
echo "----------------------------------------------"
echo "Building Express Web App → $EXPRESS_REPO:$TAG"
echo "----------------------------------------------"

docker buildx build \
  --platform "$PLATFORM" \
  -t "$ECR/$EXPRESS_REPO:$TAG" \
  --push \
  "$EXPRESS_DIR"

echo "Pushed Express: $ECR/$EXPRESS_REPO:$TAG"

###############################################
# 2) BUILD & PUSH AIOPS API
###############################################
echo
echo "----------------------------------------------"
echo "Building AIOps API → $AIOPS_REPO:$TAG"
echo "----------------------------------------------"

docker buildx build \
  --platform "$PLATFORM" \
  -t "$ECR/$AIOPS_REPO:$TAG" \
  --push \
  "$AIOPS_DIR"

echo "Pushed AIOps API: $ECR/$AIOPS_REPO:$TAG"

###############################################
# DONE
###############################################
echo
echo "===================================================="
echo "SUCCESS! Both images pushed:"
echo "  Express → $ECR/$EXPRESS_REPO:$TAG"
echo "  AIOps   → $ECR/$AIOPS_REPO:$TAG"
echo "===================================================="

echo
echo "Next steps:"
echo "  # Express redeploy"
echo "  helm upgrade --install express-web-app ./charts/express-web-app -n apps"

echo
echo "  # AIOps redeploy"
echo "  helm upgrade --install aiops ./charts/aiops -n aiops --create-namespace"
echo
