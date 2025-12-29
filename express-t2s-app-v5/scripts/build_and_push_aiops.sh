#!/usr/bin/env bash
set -euo pipefail

# =======================================================
# build_and_push_aiops.sh
# Fixes CrashLoopBackOff: exec format error
# Build AIOps API Image for linux/amd64 and push to ECR
# =======================================================

AWS_REGION="${AWS_REGION:-us-east-1}"
ACCOUNT_ID="$(aws sts get-caller-identity --query 'Account' --output text)"
ECR_REPO="aiops-api"
IMAGE_NAME="aiops-api"
TAG="latest"
PLATFORM="linux/amd64"

echo "===================================================="
echo "[AIOPS] Building AIOps API image for EKS"
echo "Account: $ACCOUNT_ID"
echo "Region: $AWS_REGION"
echo "Repo: $ECR_REPO"
echo "Platform: $PLATFORM"
echo "===================================================="

# -------------------------------------------------------
# Step 1 — Ensure ECR exists
# -------------------------------------------------------
echo "[STEP 1] Checking ECR repo exists..."

aws ecr describe-repositories \
  --repository-names "$ECR_REPO" \
  --region "$AWS_REGION" >/dev/null 2>&1 || {

  echo "[INFO] Creating ECR repo: $ECR_REPO"
  aws ecr create-repository \
      --repository-name "$ECR_REPO" \
      --image-scanning-configuration scanOnPush=true \
      --region "$AWS_REGION"
}

# -------------------------------------------------------
# Step 2 — Build Multi-Arch Safe Image (linux/amd64)
# -------------------------------------------------------
echo "----------------------------------------------------"
echo "[STEP 2] Building Docker image for $PLATFORM"
echo "----------------------------------------------------"

cd aiops-service

# Ensure buildx is enabled
docker buildx create --use >/dev/null 2>&1 || true

docker buildx build \
  --platform "$PLATFORM" \
  -t "${IMAGE_NAME}:${TAG}" \
  --load \
  .

cd ..

# -------------------------------------------------------
# Step 3 — Tag image for ECR
# -------------------------------------------------------
ECR_URI="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${TAG}"

echo "----------------------------------------------------"
echo "[STEP 3] Tagging image:"
echo "$ECR_URI"
echo "----------------------------------------------------"

docker tag "${IMAGE_NAME}:${TAG}" "$ECR_URI"

# -------------------------------------------------------
# Step 4 — Login to ECR
# -------------------------------------------------------
echo "----------------------------------------------------"
echo "[STEP 4] Logging into ECR..."
echo "----------------------------------------------------"

aws ecr get-login-password --region "$AWS_REGION" | \
  docker login --username AWS --password-stdin \
  "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# -------------------------------------------------------
# Step 5 — Push to ECR
# -------------------------------------------------------
echo "----------------------------------------------------"
echo "[STEP 5] Pushing image to ECR..."
echo "----------------------------------------------------"

docker push "$ECR_URI"

echo "===================================================="
echo "[SUCCESS] AIOps API (linux/amd64) image pushed!"
echo "Image URL:"
echo "   $ECR_URI"
echo "===================================================="

echo "[NEXT STEPS]"
echo "1. Update charts/aiops/values.yaml:"
echo ""
echo "image:"
echo "  repository: \"${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}\""
echo "  tag: \"${TAG}\""
echo "  pullPolicy: Always"
echo ""
echo "2. Redeploy AIOps:"
echo "   helm upgrade --install aiops ./charts/aiops -n aiops --create-namespace"
echo ""
echo "======================================================"
