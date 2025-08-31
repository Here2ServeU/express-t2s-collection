# Express T2S App – Full DevOps Guide (Beginner Friendly)

This project walks you through building and deploying a containerized Node.js Express application to AWS using real-world DevOps tools and best practices.

## What You’ll Learn
- How to containerize an app using Docker
- How to push images to AWS Elastic Container Registry (ECR)
- How to deploy Docker containers to AWS Elastic Container Service (ECS)
- How to use Terraform to provision cloud infrastructure
- How to manage infrastructure state using a remote S3 backend
- How to automate workflows using Bash and Python scripts

---

## Project Structure

express-t2s-app/
- app/                           → Node.js Express application source code
  - Dockerfile                   → Instructions to build Docker image
  - index.js                     → Entry point (sample Express app)

- scripts/                       → Bash and Python automation scripts
  - push_ecr.sh                  → Push Docker image to ECR (Bash)
  - push_ecr.py                  → Push Docker image to ECR (Python)
  - deploy_ecs.sh                → Deploy Docker image to ECS (Bash)
  - deploy_ecs.py                → Deploy Docker image to ECS (Python)

- terraform/                     → Infrastructure-as-code using Terraform
  - main.tf                      → Defines ECR, ECS cluster/service/task
  - backend.tf                   → Remote S3 backend for state management
  - variables.tf                 → Input variables for modularity
  - terraform.tfvars             → Actual values for variables
  - outputs.tf                   → Outputs like ECR repo URL and ECS ARNs

---

## Step-by-Step Guide for Beginners

### 1. Provision Infrastructure Using Terraform

#### Step 1. Configure Remote Backend (terraform/backend.tf)
```
terraform {
  backend "s3" {
    bucket = "your-terraform-backend-bucket"
    key    = "state/ecs-ecr/terraform.tfstate"
    region = "us-east-1"
  }
}
```
- This configuration sets up a remote backend so the Terraform state file is securely stored in an S3 bucket.

#### Step 2. Initialize Terraform
```bash
cd terraform
terraform init
```
- Initializes the working directory and configures the remote backend.

#### Step 3. Preview Infrastructure Plan
```bash
terraform plan
```
- Allows you to review changes before applying.

#### Step 4. Apply the Changes
```bash
terraform apply
```
- Provisions the entire infrastructure (ECR repo, ECS cluster, task definitions, etc.)

---

## Bash Script to Push Docker Image to ECR (scripts/push_ecr.sh)
```bash
#!/bin/bash
REPO_NAME=t2s-express-app                          # ECR repository name
REGION=us-east-1                                   # AWS region
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text) # AWS account ID
IMAGE_TAG=latest                                   # Docker image tag

# Log in to ECR using AWS CLI
aws ecr get-login-password --region $REGION | \
docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Create the repository if it doesn't exist
aws ecr describe-repositories --repository-names $REPO_NAME --region $REGION > /dev/null 2>&1 || \
aws ecr create-repository --repository-name $REPO_NAME --region $REGION

# Build, tag, and push Docker image to ECR
docker build -t $REPO_NAME ../app
docker tag $REPO_NAME:$IMAGE_TAG $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG
```

---

## Python Script to Push Docker Image to ECR (scripts/push_ecr.py)
```python
import boto3, subprocess

repo_name = "t2s-express-app"   # ECR repo name
region = "us-east-1"            # AWS region
image_tag = "latest"            # Image tag

ecr = boto3.client("ecr", region_name=region)
sts = boto3.client("sts")
account_id = sts.get_caller_identity()["Account"]
repo_uri = f"{account_id}.dkr.ecr.{region}.amazonaws.com/{repo_name}"

# Check or create ECR repo
try:
    ecr.describe_repositories(repositoryNames=[repo_name])
except ecr.exceptions.RepositoryNotFoundException:
    ecr.create_repository(repositoryName=repo_name)

# Docker login, build, tag, and push
subprocess.run(f"aws ecr get-login-password --region {region} | docker login --username AWS --password-stdin {repo_uri}", shell=True)
subprocess.run(f"docker build -t {repo_name} ../app", shell=True)
subprocess.run(f"docker tag {repo_name}:{image_tag} {repo_uri}:{image_tag}", shell=True)
subprocess.run(f"docker push {repo_uri}:{image_tag}", shell=True)
```

---

## Bash Script to Deploy Image to ECS (scripts/deploy_ecs.sh)
```bash
#!/bin/bash
CLUSTER_NAME=t2s-ecs-cluster       # ECS cluster name
SERVICE_NAME=t2s-ecs-service       # ECS service name

# Redeploy service with latest image
aws ecs update-service \
  --cluster $CLUSTER_NAME \
  --service $SERVICE_NAME \
  --force-new-deployment
```

---

## Python Script to Deploy Image to ECS (scripts/deploy_ecs.py)
```python
import boto3

client = boto3.client('ecs')

# Redeploy service with latest image
client.update_service(
    cluster='t2s-ecs-cluster',
    service='t2s-ecs-service',
    forceNewDeployment=True
)
```

---

## Summary of Terraform Files
- `main.tf`: Declares resources like ECS cluster, service, task definition, IAM roles, and ECR.
- `variables.tf`: Defines reusable input variables.
- `terraform.tfvars`: Actual values used in the variables.
- `outputs.tf`: Displays useful output like ECR repo URI or ECS service name.
- `backend.tf`: Defines remote S3 backend for storing Terraform state.

---

## How to Run
```bash
# Terraform infra
cd terraform
terraform init
terraform apply

# Push Docker image (option 1)
cd scripts
bash push_ecr.sh

# Push Docker image (option 2)
python3 push_ecr.py

# Deploy to ECS (option 1)
bash deploy_ecs.sh

# Deploy to ECS (option 2)
python3 deploy_ecs.py
```

---
## Author

**Dr. Emmanuel Naweji (2025)**  
Cloud | DevOps | SRE | FinOps | AI Mentor  
GitHub: [Here2ServeU](https://github.com/Here2ServeU)
LinkedIn: [emmanuelnaweji](https://www.linkedin.com/in/ready2assist/) 
Medium: [@here2serveyou](https://medium.com/@here2serveyou)  
Book a Free 30-Minute Consultation: [naweji.setmore.com](https://here4you.setmore.com/emmanuel)
