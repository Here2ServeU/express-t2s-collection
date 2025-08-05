#!/bin/bash

# Set environment variables
REPO_NAME="t2s-express-app"
REGION="us-east-1"
CLUSTER_NAME="t2s-ecs-cluster"
SERVICE_NAME="t2s-ecs-service"
TASK_FAMILY="t2s-task-family"
APP_PATH="./app"  # Fixed app path

# Get AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
IMAGE_TAG="latest"
REPO_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME"

# Authenticate Docker to ECR
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $REPO_URI

# Create ECR repository if it doesn't exist
aws ecr describe-repositories --repository-names $REPO_NAME --region $REGION > /dev/null 2>&1
if [ $? -ne 0 ]; then
  aws ecr create-repository --repository-name $REPO_NAME --region $REGION
fi

# Build and push Docker image
docker build -t $REPO_NAME $APP_PATH
docker tag $REPO_NAME:$IMAGE_TAG $REPO_URI:$IMAGE_TAG
docker push $REPO_URI:$IMAGE_TAG

# Create ECS cluster if not exists
aws ecs create-cluster --cluster-name $CLUSTER_NAME || true

# Create IAM role for ECS task execution if not exists
ROLE_NAME="ecsTaskExecutionRole"
aws iam get-role --role-name $ROLE_NAME > /dev/null 2>&1
if [ $? -ne 0 ]; then
  TRUST="{
    \"Version\": \"2012-10-17\",
    \"Statement\": [
      {
        \"Effect\": \"Allow\",
        \"Principal\": {
          \"Service\": \"ecs-tasks.amazonaws.com\"
        },
        \"Action\": \"sts:AssumeRole\"
      }
    ]
  }"
  echo $TRUST > trust-policy.json
  aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document file://trust-policy.json
  aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
  sleep 10
fi

# Get default VPC subnets and security group
SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=default-for-az,Values=true" --query "Subnets[0].SubnetId" --output text)
SG_ID=$(aws ec2 describe-security-groups --filters Name=group-name,Values=default --query "SecurityGroups[0].GroupId" --output text)

# Register ECS task definition
cat <<EOF > task-def.json
{
  "family": "t2s-task-family",
  "requiresCompatibilities": ["FARGATE"],
  "networkMode": "awsvpc",
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME",
  "containerDefinitions": [
    {
      "name": "$REPO_NAME",
      "image": "$REPO_URI:$IMAGE_TAG",
      "memory": 512,
      "cpu": 256,
      "essential": true,
      "portMappings": [
        {
          "containerPort": 3000,
          "protocol": "tcp"
        }
      ]
    }
  ]
}
EOF

aws ecs register-task-definition --cli-input-json file://task-def.json

# Create or update ECS service
SERVICE_EXISTS=$(aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --query "services[0].status" --output text)
if [ "$SERVICE_EXISTS" == "MISSING" ]; then
  aws ecs create-service \
    --cluster $CLUSTER_NAME \
    --service-name $SERVICE_NAME \
    --task-definition $TASK_FAMILY \
    --desired-count 1 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_ID],securityGroups=[$SG_ID],assignPublicIp=ENABLED}"
else
  aws ecs update-service \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --task-definition $TASK_FAMILY
fi

echo "Deployment to ECS completed!"
