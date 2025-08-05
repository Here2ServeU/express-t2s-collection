#!/bin/bash

# ===== Configuration =====
REPO_NAME="t2s-express-app"
REGION="us-east-1"
CLUSTER_NAME="t2s-ecs-cluster"
SERVICE_NAME="t2s-ecs-service"
TASK_FAMILY="t2s-task-family"
SECURITY_GROUP_NAME="t2s-express-sg"
VPC_ID=""
PORT=3000
IMAGE_TAG="latest"

# ===== AWS Account Info =====
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REPO_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME"

# ===== ECR Login & Repo =====
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $REPO_URI

aws ecr describe-repositories --repository-names $REPO_NAME --region $REGION > /dev/null 2>&1
if [ $? -ne 0 ]; then
  aws ecr create-repository --repository-name $REPO_NAME --region $REGION
fi

docker build -t $REPO_NAME ./../app
docker tag $REPO_NAME:$IMAGE_TAG $REPO_URI:$IMAGE_TAG
docker push $REPO_URI:$IMAGE_TAG

# ===== Find Default VPC =====
if [ -z "$VPC_ID" ]; then
  VPC_ID=$(aws ec2 describe-vpcs \
    --filters Name=isDefault,Values=true \
    --region $REGION \
    --query 'Vpcs[0].VpcId' --output text)
fi

# ===== Find Public Subnet =====
SUBNET_ID=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=default-for-az,Values=true" \
  --region $REGION \
  --query 'Subnets[0].SubnetId' --output text)

# ===== Create Security Group if Needed =====
SG_ID=$(aws ec2 describe-security-groups \
  --filters Name=group-name,Values=$SECURITY_GROUP_NAME Name=vpc-id,Values=$VPC_ID \
  --region $REGION \
  --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null)

if [ "$SG_ID" == "None" ] || [ -z "$SG_ID" ]; then
  SG_ID=$(aws ec2 create-security-group \
    --group-name $SECURITY_GROUP_NAME \
    --description "Security group for $REPO_NAME" \
    --vpc-id $VPC_ID \
    --region $REGION \
    --query 'GroupId' --output text)

  aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port $PORT \
    --cidr 0.0.0.0/0 \
    --region $REGION
fi

# ===== Create ECS Cluster if Needed =====
aws ecs describe-clusters --clusters $CLUSTER_NAME --region $REGION > /dev/null 2>&1
if [ $? -ne 0 ]; then
  aws ecs create-cluster --cluster-name $CLUSTER_NAME --region $REGION
fi

# ===== Register Task Definition =====
cat > task-def.json <<EOF
{
  "family": "$TASK_FAMILY",
  "requiresCompatibilities": ["FARGATE"],
  "networkMode": "awsvpc",
  "cpu": "256",
  "memory": "512",
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
          "protocol": "tcp"
        }
      ]
    }
  ]
}
EOF

aws ecs register-task-definition --cli-input-json file://task-def.json --region $REGION

# ===== Deploy or Update ECS Service =====
SERVICE_EXISTS=$(aws ecs describe-services \
  --cluster $CLUSTER_NAME \
  --services $SERVICE_NAME \
  --region $REGION \
  --query "services[0].status" --output text 2>/dev/null)

if [ "$SERVICE_EXISTS" == "ACTIVE" ]; then
  aws ecs update-service \
    --cluster $CLUSTER_NAME \
    --service $SERVICE_NAME \
    --task-definition $TASK_FAMILY \
    --force-new-deployment \
    --region $REGION
else
  aws ecs create-service \
    --cluster $CLUSTER_NAME \
    --service-name $SERVICE_NAME \
    --task-definition $TASK_FAMILY \
    --desired-count 1 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_ID],securityGroups=[$SG_ID],assignPublicIp=ENABLED}" \
    --region $REGION
fi

echo "Deployment complete."
