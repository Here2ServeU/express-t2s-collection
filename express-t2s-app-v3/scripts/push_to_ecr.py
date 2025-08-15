import boto3
import subprocess
import sys
import os

REPO_NAME = "t2s-express-app"
REGION = "us-east-1"
IMAGE_TAG = "latest"
DOCKERFILE_PATH = "./app"  # Path to the directory containing Dockerfile

# Step 1: Get AWS account ID
sts = boto3.client("sts")
account_id = sts.get_caller_identity()["Account"]
repository_uri = f"{account_id}.dkr.ecr.{REGION}.amazonaws.com/{REPO_NAME}:{IMAGE_TAG}"

# Step 2: Authenticate Docker to ECR
try:
    print("Logging in to ECR...")
    login_cmd = subprocess.run(
        ["aws", "ecr", "get-login-password", "--region", REGION],
        check=True,
        stdout=subprocess.PIPE,
        text=True
    )
    subprocess.run(
        [
            "docker", "login",
            "--username", "AWS",
            "--password-stdin",
            f"{account_id}.dkr.ecr.{REGION}.amazonaws.com"
        ],
        input=login_cmd.stdout,
        check=True
    )
except subprocess.CalledProcessError:
    print("Failed to authenticate with ECR")
    sys.exit(1)

# Step 3: Create ECR repo if it doesn't exist
ecr = boto3.client("ecr", region_name=REGION)
try:
    print(f"🔎 Checking if ECR repository '{REPO_NAME}' exists...")
    ecr.describe_repositories(repositoryNames=[REPO_NAME])
    print(f"Repository '{REPO_NAME}' already exists.")
except ecr.exceptions.RepositoryNotFoundException:
    print(f"Creating ECR repository '{REPO_NAME}'...")
    ecr.create_repository(repositoryName=REPO_NAME)

# Step 4: Build Docker image (Dockerfile is in ./app)
print("Building Docker image...")
subprocess.run(["docker", "build", "-t", f"{REPO_NAME}:{IMAGE_TAG}", DOCKERFILE_PATH], check=True)

# Step 5: Tag the image
print(️" agging Docker image...")
subprocess.run(["docker", "tag", f"{REPO_NAME}:{IMAGE_TAG}", repository_uri], check=True)

# Step 6: Push the image to ECR
print("Pushing image to ECR...")
subprocess.run(["docker", "push", repository_uri], check=True)

print(f" Deployment complete: {repository_uri}")
