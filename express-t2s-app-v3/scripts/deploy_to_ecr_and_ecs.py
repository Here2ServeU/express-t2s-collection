import boto3
import subprocess
import json

repo_name = "t2s-express-app"
region = "us-east-1"
image_tag = "latest"
cluster_name = "express-cluster"
task_family = "express-task"

ecr = boto3.client("ecr", region_name=region)
ecs = boto3.client("ecs", region_name=region)
sts = boto3.client("sts")
account_id = sts.get_caller_identity()["Account"]
repo_uri = f"{account_id}.dkr.ecr.{region}.amazonaws.com/{repo_name}"

try:
    ecr.describe_repositories(repositoryNames=[repo_name])
except ecr.exceptions.RepositoryNotFoundException:
    ecr.create_repository(repositoryName=repo_name)

subprocess.run(f"aws ecr get-login-password --region {region} | docker login --username AWS --password-stdin {repo_uri}", shell=True, check=True)
subprocess.run(f"docker build -t {repo_name} ./../app", shell=True, check=True)
subprocess.run(f"docker tag {repo_name}:{image_tag} {repo_uri}:{image_tag}", shell=True, check=True)
subprocess.run(f"docker push {repo_uri}:{image_tag}", shell=True, check=True)

task_def = {
    "family": task_family,
    "networkMode": "awsvpc",
    "containerDefinitions": [{
        "name": "express-container",
        "image": f"{repo_uri}:{image_tag}",
        "portMappings": [{"containerPort": 3000, "hostPort": 3000}],
        "essential": True
    }],
    "requiresCompatibilities": ["FARGATE"],
    "cpu": "256",
    "memory": "512",
    "executionRoleArn": f"arn:aws:iam::{account_id}:role/ecsTaskExecutionRole"
}

with open("taskdef.json", "w") as f:
    json.dump(task_def, f)

subprocess.run("aws ecs register-task-definition --cli-input-json file://taskdef.json", shell=True, check=True)