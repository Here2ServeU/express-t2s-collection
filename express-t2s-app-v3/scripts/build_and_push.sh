#!/bin/bash
set -e
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=us-east-1
REPO_NAME=express-t2s
IMAGE_URI=$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:latest

aws ecr describe-repositories --repository-names $REPO_NAME --region $REGION ||   aws ecr create-repository --repository-name $REPO_NAME --region $REGION

docker build -t $REPO_NAME ./app
docker tag $REPO_NAME:latest $IMAGE_URI
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com
docker push $IMAGE_URI
echo "Image pushed to: $IMAGE_URI"
