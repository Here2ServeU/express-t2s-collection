#!/bin/bash

set -e

APP_DIR="./app"
PUBLIC_DIR="./app/public"
AWS_REGION="us-east-1"
REPO_NAME="t2s-express-app"
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
ECR_URI="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}"
IMAGE_TAG="latest"

# Authenticate Docker with AWS ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URI

# Copy index.html to app/public if needed (optional, depending on static hosting config)

# Build Docker image
docker build -t ${REPO_NAME}:${IMAGE_TAG} ${APP_DIR}

# Tag image
docker tag ${REPO_NAME}:${IMAGE_TAG} ${ECR_URI}:${IMAGE_TAG}

# Push image to ECR
docker push ${ECR_URI}:${IMAGE_TAG}
