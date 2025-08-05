#!/bin/bash

set -e

# --------- VARIABLES ---------
REGION="us-east-1"
ECR_REPO="t2s-express-app"
ECS_CLUSTER="t2s-ecs-cluster"
ECS_SERVICE="t2s-ecs-service"
EKS_CLUSTER="t2s-eks-cluster"

echo "Starting cleanup for ECS, EKS, and ECR resources..."
echo

# --------- CLEAN UP ECS ---------
echo "Checking ECS service: $ECS_SERVICE..."

ECS_SERVICE_STATUS=$(aws ecs describe-services \
  --cluster $ECS_CLUSTER \
  --services $ECS_SERVICE \
  --region $REGION \
  --query "services[0].status" \
  --output text 2>/dev/null || echo "None")

if [ "$ECS_SERVICE_STATUS" != "None" ]; then
  echo "Deleting ECS service..."
  aws ecs update-service \
    --cluster $ECS_CLUSTER \
    --service $ECS_SERVICE \
    --desired-count 0 \
    --region $REGION >/dev/null

  aws ecs delete-service \
    --cluster $ECS_CLUSTER \
    --service $ECS_SERVICE \
    --region $REGION \
    --force
else
  echo "ECS service not found or already deleted."
fi

echo "Checking ECS cluster: $ECS_CLUSTER..."

ECS_CLUSTER_STATUS=$(aws ecs describe-clusters \
  --clusters $ECS_CLUSTER \
  --region $REGION \
  --query "clusters[0].status" \
  --output text 2>/dev/null || echo "None")

if [ "$ECS_CLUSTER_STATUS" != "None" ]; then
  echo "Deleting ECS cluster..."
  aws ecs delete-cluster --cluster $ECS_CLUSTER --region $REGION
else
  echo "ECS cluster not found or already deleted."
fi

echo

# --------- CLEAN UP EKS ---------
echo "Checking EKS cluster: $EKS_CLUSTER..."

EKS_EXISTS=$(aws eks describe-cluster \
  --name $EKS_CLUSTER \
  --region $REGION \
  --query "cluster.status" \
  --output text 2>/dev/null || echo "None")

if [ "$EKS_EXISTS" != "None" ]; then
  echo "Deleting EKS cluster..."
  aws eks delete-cluster --name $EKS_CLUSTER --region $REGION
else
  echo "EKS cluster not found or already deleted."
fi

echo

# --------- CLEAN UP ECR ---------
echo "Checking ECR repository: $ECR_REPO..."

REPO_EXISTS=$(aws ecr describe-repositories \
  --repository-names $ECR_REPO \
  --region $REGION \
  --query "repositories[0].repositoryUri" \
  --output text 2>/dev/null || echo "None")

if [ "$REPO_EXISTS" != "None" ]; then
  echo "Listing images in ECR repository..."
  IMAGE_TAGS=$(aws ecr list-images \
    --repository-name $ECR_REPO \
    --region $REGION \
    --query 'imageIds[*]' \
    --output json)

  if [ "$IMAGE_TAGS" != "[]" ]; then
    echo "Deleting images from ECR repository..."
    aws ecr batch-delete-image \
      --repository-name $ECR_REPO \
      --region $REGION \
      --image-ids "$IMAGE_TAGS"
  fi

  echo "Deleting ECR repository..."
  aws ecr delete-repository --repository-name $ECR_REPO --region $REGION --force
else
  echo "ECR repository not found or already deleted."
fi

echo
echo "Cleanup complete for ECS, EKS, and ECR."
