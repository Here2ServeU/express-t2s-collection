#!/bin/bash

REPO_NAME=t2s-express-app
REGION=us-east-1
CLUSTER_NAME=t2s-ecs-cluster
SERVICE_NAME=t2s-ecs-service
TASK_FAMILY=t2s-task-family

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
IMAGE_TAG=latest
REPO_URI=$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME

aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $REPO_URI

aws ecr describe-repositories --repository-names $REPO_NAME --region $REGION > /dev/null 2>&1
if [ $? -ne 0 ]; then
  aws ecr create-repository --repository-name $REPO_NAME --region $REGION
fi

docker build -t $REPO_NAME .
docker tag $REPO_NAME:$IMAGE_TAG $REPO_URI:$IMAGE_TAG
docker push $REPO_URI:$IMAGE_TAG

# Deploy ECS task and service if not exists
aws ecs create-cluster --cluster-name $CLUSTER_NAME || true

TASK_DEF=$(cat <<EOF
{
  "family": "$TASK_FAMILY",
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
          "hostPort": 3000
        }
      ]
    }
  ]
}
EOF
)

echo "$TASK_DEF" > task-def.json
aws ecs register-task-definition --cli-input-json file://task-def.json

aws ecs create-service --cluster $CLUSTER_NAME --service-name $SERVICE_NAME --task-definition $TASK_FAMILY   --desired-count 1 --launch-type FARGATE   --network-configuration "awsvpcConfiguration={subnets=[subnet-12345678],securityGroups=[sg-12345678],assignPublicIp=ENABLED}" || true
