import boto3
import subprocess
import json
import os

# Configuration
repo_name = "t2s-express-app"
region = "us-east-1"
image_tag = "latest"
cluster_name = "express-cluster"
task_family = "express-task"
container_name = "express-container"
role_name = "ecsTaskExecutionRole"

# AWS clients
ecr = boto3.client("ecr", region_name=region)
ecs = boto3.client("ecs", region_name=region)
iam = boto3.client("iam", region_name=region)
sts = boto3.client("sts", region_name=region)
account_id = sts.get_caller_identity()["Account"]
repo_uri = f"{account_id}.dkr.ecr.{region}.amazonaws.com/{repo_name}"

# Create ECR repo if not exists
try:
    ecr.describe_repositories(repositoryNames=[repo_name])
    print(f"ECR repository '{repo_name}' already exists.")
except ecr.exceptions.RepositoryNotFoundException:
    ecr.create_repository(repositoryName=repo_name)
    print(f"ECR repository '{repo_name}' created.")

# Create IAM role if not exists
try:
    iam.get_role(RoleName=role_name)
    print(f"IAM role '{role_name}' already exists.")
except iam.exceptions.NoSuchEntityException:
    assume_role_policy = {
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Principal": {"Service": "ecs-tasks.amazonaws.com"},
            "Action": "sts:AssumeRole"
        }]
    }
    iam.create_role(
        RoleName=role_name,
        AssumeRolePolicyDocument=json.dumps(assume_role_policy)
    )
    iam.attach_role_policy(
        RoleName=role_name,
        PolicyArn="arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
    )
    print(f"IAM role '{role_name}' created and policy attached.")

# Authenticate Docker with ECR
subprocess.run(
    f"aws ecr get-login-password --region {region} | docker login --username AWS --password-stdin {repo_uri}",
    shell=True, check=True
)

# Build and push Docker image
subprocess.run(f"docker build -t {repo_name} ./../app", shell=True, check=True)
subprocess.run(f"docker tag {repo_name}:{image_tag} {repo_uri}:{image_tag}", shell=True, check=True)
subprocess.run(f"docker push {repo_uri}:{image_tag}", shell=True, check=True)

# Create ECS cluster if not exists
clusters = ecs.list_clusters()["clusterArns"]
if not any(cluster_name in arn for arn in clusters):
    ecs.create_cluster(clusterName=cluster_name)
    print(f"ECS Cluster '{cluster_name}' created.")
else:
    print(f"ECS Cluster '{cluster_name}' already exists.")

# Register ECS task definition
task_def = {
    "family": task_family,
    "networkMode": "awsvpc",
    "containerDefinitions": [{
        "name": container_name,
        "image": f"{repo_uri}:{image_tag}",
        "portMappings": [{"containerPort": 3000}],
        "essential": True
    }],
    "requiresCompatibilities": ["FARGATE"],
    "cpu": "256",
    "memory": "512",
    "executionRoleArn": f"arn:aws:iam::{account_id}:role/{role_name}"
}

with open("taskdef.json", "w") as f:
    json.dump(task_def, f, indent=2)

subprocess.run("aws ecs register-task-definition --cli-input-json file://taskdef.json", shell=True, check=True)
print("Task definition registered and ready.")
