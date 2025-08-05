#!/bin/bash

set -e

ECS_CLUSTER="t2s-ecs-cluster"
ECS_SERVICE="t2s-ecs-service"
EKS_CLUSTER="t2s-eks-cluster"
REGION="us-east-1"

echo "Starting cleanup process..."

# Delete ECS service
echo "Checking for ECS service: $ECS_SERVICE in cluster: $ECS_CLUSTER..."
SERVICE_EXISTS=$(aws ecs describe-services \
  --cluster $ECS_CLUSTER \
  --services $ECS_SERVICE \
  --query "services[0].status" \
  --output text \
  --region $REGION 2>/dev/null || echo "None")

if [ "$SERVICE_EXISTS" != "None" ]; then
  echo "Deleting ECS service..."
  aws ecs delete-service --cluster $ECS_CLUSTER --service $ECS_SERVICE --force --region $REGION
else
  echo "ECS service not found or already deleted."
fi

# Delete ECS cluster
echo "Deleting ECS cluster: $ECS_CLUSTER..."
aws ecs delete-cluster --cluster $ECS_CLUSTER --region $REGION || echo "ECS cluster already deleted or not found."

# Delete EKS cluster
echo "Checking for EKS cluster: $EKS_CLUSTER..."
EKS_EXISTS=$(aws eks describe-cluster --name $EKS_CLUSTER --region $REGION --query "cluster.status" --output text 2>/dev/null || echo "None")

if [ "$EKS_EXISTS" != "None" ]; then
  echo "Deleting EKS cluster: $EKS_CLUSTER..."
  aws eks delete-cluster --name $EKS_CLUSTER --region $REGION
else
  echo "EKS cluster not found or already deleted."
fi

echo "Cleanup completed."
