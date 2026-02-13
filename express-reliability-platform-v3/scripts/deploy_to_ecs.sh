#!/bin/bash
CLUSTER_NAME=express-cluster
SERVICE_NAME=express-service
TASK_FAMILY=express-task
REGION=us-east-1
REPO_NAME=t2s-express-app
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
IMAGE=$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:latest

aws ecs create-cluster --cluster-name $CLUSTER_NAME

TASK_DEF=$(cat <<EOF
{
  "family": "$TASK_FAMILY",
  "networkMode": "awsvpc",
  "containerDefinitions": [
    {
      "name": "express-container",
      "image": "$IMAGE",
      "portMappings": [
        {
          "containerPort": 3000,
          "hostPort": 3000,
          "protocol": "tcp"
        }
      ],
      "essential": true
    }
  ],
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::${ACCOUNT_ID}:role/ecsTaskExecutionRole"
}
EOF
)

echo "$TASK_DEF" > taskdef.json
aws ecs register-task-definition --cli-input-json file://taskdef.json