#!/bin/bash

# === CONFIGURATION ===
REPO_NAME="t2s-express-app"
REGION="us-east-1"
CLUSTER_NAME="t2s-ecs-cluster"
SERVICE_NAME="t2s-ecs-service"
TASK_FAMILY="t2s-task-family"
IMAGE_TAG="latest"
APP_PATH="../app"

# === AWS ACCOUNT INFO ===
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REPO_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME"

# === LOG IN TO ECR ===
echo "Logging in to AWS ECR..."
aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin $REPO_URI

# === ENSURE ECR REPO EXISTS ===
aws ecr describe-repositories --repository-names $REPO_NAME --region $REGION > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Creating ECR repository: $REPO_NAME"
  aws ecr create-repository --repository-name $REPO_NAME --region $REGION
fi

# === BUILD & PUSH DOCKER IMAGE ===
echo "Building and pushing Docker image..."
docker build -t $REPO_NAME $APP_PATH
docker tag $REPO_NAME:$IMAGE_TAG $REPO_URI:$IMAGE_TAG
docker push $REPO_URI:$IMAGE_TAG

# === FIND DEFAULT VPC SUBNET ===
SUBNET_ID=$(aws ec2 describe-subnets \
  --filters "Name=default-for-az,Values=true" \
  --query "Subnets[0].SubnetId" \
  --region $REGION --output text)

# === FIND OR CREATE SECURITY GROUP ===
SECURITY_GROUP_NAME="t2s-ecs-sg"
SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
  --filters Name=group-name,Values=$SECURITY_GROUP_NAME \
  --query "SecurityGroups[0].GroupId" \
  --region $REGION --output text 2>/dev/null)

if [ "$SECURITY_GROUP_ID" == "None" ] || [ -z "$SECURITY_GROUP_ID" ]; then
  echo "Creating security group..."
  SECURITY_GROUP_ID=$(aws ec2 create-security-group \
    --group-name $SECURITY_GROUP_NAME \
    --description "Allow traffic to ECS containers" \
    --vpc-id $(aws ec2 describe-vpcs --region $REGION --query "Vpcs[0].VpcId" --output text) \
    --region $REGION \
    --query "GroupId" --output text)

  aws ec2 authorize-security-group-ingress \
    --group-id $SECURITY_GROUP_ID \
    --protocol tcp \
    --port 3000 \
    --cidr 0.0.0.0/0 \
    --region $REGION
fi

# === CREATE EXECUTION ROLE IF NOT EXISTS ===
ROLE_NAME="ecsTaskExecutionRole"
aws iam get-role --role-name $ROLE_NAME --region $REGION > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Creating IAM role: $ROLE_NAME"
  aws iam create-role --role-name $ROLE_NAME \
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
) --region $REGION

  aws iam attach-role-policy --role-name $ROLE_NAME \
    --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy \
    --region $REGION
fi

EXEC_ROLE_ARN=$(aws iam get-role --role-name $ROLE_NAME --region $REGION --query "Role.Arn" --output text)

# === CREATE OR CONFIRM CLUSTER ===
aws ecs describe-clusters --clusters $CLUSTER_NAME --region $REGION --query "clusters[0].status" --output text 2>/dev/null | grep -q "ACTIVE"
if [ $? -ne 0 ]; then
  echo "Creating ECS cluster: $CLUSTER_NAME"
  aws ecs create-cluster --cluster-name $CLUSTER_NAME --region $REGION
fi

# === REGISTER TASK DEFINITION ===
echo "Registering task definition..."
cat <<EOF > task-def.json
{
  "family": "$TASK_FAMILY",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "$EXEC_ROLE_ARN",
  "containerDefinitions": [
    {
      "name": "$REPO_NAME",
      "image": "$REPO_URI:$IMAGE_TAG",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 3000,
          "hostPort": 3000,
          "protocol": "tcp"
        }
      ]
    }
  ]
}
EOF

aws ecs register-task-definition \
  --cli-input-json file://task-def.json \
  --region $REGION

# === CREATE OR UPDATE SERVICE ===
SERVICE_EXISTS=$(aws ecs describe-services \
  --cluster $CLUSTER_NAME \
  --services $SERVICE_NAME \
  --region $REGION \
  --query "services[0].status" \
  --output text 2>/dev/null)

if [ "$SERVICE_EXISTS" != "ACTIVE" ]; then
  echo "Creating ECS service..."
  aws ecs create-service \
    --cluster $CLUSTER_NAME \
    --service-name $SERVICE_NAME \
    --task-definition $TASK_FAMILY \
    --launch-type FARGATE \
    --desired-count 1 \
    --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_ID],securityGroups=[$SECURITY_GROUP_ID],assignPublicIp=ENABLED}" \
    --region $REGION

  if [ $? -eq 0 ]; then
    echo "ECS deployment completed successfully."
  else
    echo "ECS deployment failed during service creation."
  fi
else
  echo "Updating ECS service..."
  aws ecs update-service \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --force-new-deployment \
    --region $REGION

  if [ $? -eq 0 ]; then
    echo "ECS deployment updated successfully."
  else
    echo "ECS deployment failed during service update."
  fi
fi
