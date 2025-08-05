#!/bin/bash

set -e

REPO_NAME=t2s-express-app
REGION=us-east-1
CLUSTER_NAME=t2s-ecs-cluster
SERVICE_NAME=t2s-ecs-service
TASK_FAMILY=t2s-task-family
SECURITY_GROUP_NAME=t2s-ecs-sg
PORT=3000

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REPO_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME"
IMAGE_TAG=latest

echo "Authenticating with ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $REPO_URI

echo "Checking for existing ECR repository..."
aws ecr describe-repositories --repository-names $REPO_NAME --region $REGION > /dev/null 2>&1 || \
aws ecr create-repository --repository-name $REPO_NAME --region $REGION

echo "Building and pushing Docker image..."
docker build -t $REPO_NAME ./../app
docker tag $REPO_NAME:$IMAGE_TAG $REPO_URI:$IMAGE_TAG
docker push $REPO_URI:$IMAGE_TAG

echo "Creating ECS cluster if it does not exist..."
aws ecs describe-clusters --clusters $CLUSTER_NAME --region $REGION | grep -q ACTIVE || \
aws ecs create-cluster --cluster-name $CLUSTER_NAME --region $REGION

echo "Checking for security group..."
SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters Name=group-name,Values=$SECURITY_GROUP_NAME --query "SecurityGroups[0].GroupId" --output text)

if [ "$SECURITY_GROUP_ID" == "None" ]; then
  echo "Creating new security group..."
  VPC_ID=$(aws ec2 describe-vpcs --query "Vpcs[0].VpcId" --output text)
  SECURITY_GROUP_ID=$(aws ec2 create-security-group --group-name $SECURITY_GROUP_NAME --description "Security group for ECS" --vpc-id $VPC_ID --output text)
  aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port $PORT --cidr 0.0.0.0/0
fi

echo "Getting subnet ID..."
SUBNET_ID=$(aws ec2 describe-subnets --query "Subnets[0].SubnetId" --output text)

echo "Checking for IAM role..."
ROLE_NAME="ecsTaskExecutionRole"
ROLE_EXISTS=$(aws iam get-role --role-name $ROLE_NAME --query "Role.RoleName" --output text 2>/dev/null || echo "None")
if [ "$ROLE_EXISTS" == "None" ]; then
  echo "Creating IAM role..."
  aws iam create-role \
    --role-name $ROLE_NAME \
    --assume-role-policy-document file://<(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "ecs-tasks.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
)
  aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
fi

echo "Registering ECS task definition..."
cat > task-def.json <<EOF
{
  "family": "$TASK_FAMILY",
  "networkMode": "awsvpc",
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
          "containerPort": $PORT,
          "hostPort": $PORT,
          "protocol": "tcp"
        }
      ]
    }
  ],
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512"
}
EOF

aws ecs register-task-definition --cli-input-json file://task-def.json

echo "Checking if ECS service exists..."
SERVICE_EXISTS=$(aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --query "services[0].status" --output text 2>/dev/null || echo "None")

if [ "$SERVICE_EXISTS" == "ACTIVE" ]; then
  echo "Updating ECS service..."
  aws ecs update-service \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --task-definition $TASK_FAMILY \
    --region $REGION
else
  echo "Creating ECS service..."
  aws ecs create-service \
    --cluster $CLUSTER_NAME \
    --service-name $SERVICE_NAME \
    --task-definition $TASK_FAMILY \
    --desired-count 1 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_ID],securityGroups=[$SECURITY_GROUP_ID],assignPublicIp=ENABLED}"
fi

echo "Waiting 30 seconds for ECS task to start..."
sleep 30

TASK_ARN=$(aws ecs list-tasks --cluster $CLUSTER_NAME --service-name $SERVICE_NAME --desired-status STOPPED --query 'taskArns[0]' --output text)

if [ "$TASK_ARN" != "None" ]; then
  echo "Deployment failed. ECS task stopped prematurely."
  EXIT_CODE=$(aws ecs describe-tasks --cluster $CLUSTER_NAME --tasks $TASK_ARN --query 'tasks[0].containers[0].exitCode' --output text)
  echo "Task exited with code: $EXIT_CODE"
  echo "Check CloudWatch logs for details."
else
  echo "Deployment to ECS succeeded. The application should now be running."
fi
