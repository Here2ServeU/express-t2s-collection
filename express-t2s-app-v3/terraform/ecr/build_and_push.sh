#!/bin/bash

set -e

# Set app directory relative to this script's location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="${SCRIPT_DIR}/../app"
AWS_REGION="us-east-1"
REPO_NAME="t2s-express-app"
IMAGE_TAG="latest"

# Verify APP_DIR exists
if [ ! -d "$APP_DIR" ]; then
  echo "Error: Application directory not found at: $APP_DIR"
  exit 1
fi

# Get AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

# Construct ECR URI
ECR_URI="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}"

# Authenticate Docker with AWS ECR
echo "Logging into AWS ECR..."
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_URI"

# Build Docker image
echo "Building Docker image from $APP_DIR..."
docker build -t "${REPO_NAME}:${IMAGE_TAG}" "$APP_DIR"

# Tag image
docker tag "${REPO_NAME}:${IMAGE_TAG}" "${ECR_URI}:${IMAGE_TAG}"

# Push image to ECR
echo "Pushing image to ECR: ${ECR_URI}:${IMAGE_TAG}"
docker push "${ECR_URI}:${IMAGE_TAG}"

echo "✅ Docker image pushed successfully!"
