#!/bin/bash

set -e

# Set working directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="${SCRIPT_DIR}/../../app"
AWS_REGION="us-east-1"
REPO_NAME="t2s-express-app"
IMAGE_TAG="latest"

# Validate app directory exists
if [ ! -d "$APP_DIR" ]; then
  echo "Error: Application directory not found at: $APP_DIR"
  exit 1
fi

# Get AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

# Compose ECR URI
ECR_URI="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}"

echo "Logging into AWS ECR..."
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_URI"

echo "Building Docker image from: $APP_DIR"
docker build -t "${REPO_NAME}:${IMAGE_TAG}" "$APP_DIR"

echo "Tagging Docker image"
docker tag "${REPO_NAME}:${IMAGE_TAG}" "${ECR_URI}:${IMAGE_TAG}"

echo "Pushing image to ECR: ${ECR_URI}:${IMAGE_TAG}"
docker push "${ECR_URI}:${IMAGE_TAG}"

echo "Image pushed successfully."
