#!/bin/bash

REPO_NAME=t2s-express-app
REGION=us-east-1
IMAGE_TAG=latest

# Get AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Authenticate Docker with ECR
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Create ECR repository if it doesn't exist
aws ecr describe-repositories --repository-names $REPO_NAME --region $REGION > /dev/null 2>&1
if [ $? -ne 0 ]; then
  aws ecr create-repository --repository-name $REPO_NAME --region $REGION
fi

# Build Docker image from the app/ directory
docker build -t $REPO_NAME:$IMAGE_TAG ./app

# Tag the image for ECR
docker tag $REPO_NAME:$IMAGE_TAG $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG

# Push the image to ECR
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG
