# Express T2S App – version 3: Full DevOps Guide (Beginner Friendly)

This project walks you through building and deploying a containerized Node.js Express application to AWS using real-world DevOps tools and best practices.

## What You’ll Learn
- How to containerize an app using Docker
- How to push images to AWS Elastic Container Registry (ECR)
- How to deploy Docker containers to AWS Elastic Container Service (ECS)
- **How to set up a secure Network (VPC) and Application Load Balancer (ALB)**
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
  - main.tf                      → Defines Network, ALB, ECS cluster/service/task
  - backend.tf                   → Remote S3 backend for state management
  - variables.tf                 → Input variables for modularity
  - terraform.tfvars             → Actual values for variables
  - outputs.tf                   → Outputs like ALB DNS Name and ECR repo URL

---

## Infrastructure Deep Dive (New!)

This project deploys a production-ready architecture. Here is how the components work together:

### 1. Network Infrastructure (VPC & Subnets)
Instead of using the default VPC, we create a **Custom VPC** with an **Internet Gateway (IGW)**.
- **Public Subnets:** We deploy subnets across multiple Availability Zones (AZs) to ensure high availability.
- **Why it matters:** The Internet Gateway allows our Fargate tasks to reach out to ECR to pull Docker images, and allows the Load Balancer to accept traffic from users on the internet.

### 2. Application Load Balancer (ALB)
The ALB acts as the single entry point for your application.
- It listens for incoming traffic on **Port 80 (HTTP)** from the internet.
- It automatically distributes this traffic evenly to your running containers.
- **Health Checks:** The ALB constantly checks if your containers are healthy. If a container fails, the ALB stops sending traffic to it until it recovers.

### 3. Security Groups (Firewalls)
We use a "Security in Depth" approach with two distinct security groups:
- **ALB Security Group:** Open to the world (`0.0.0.0/0`) on Port 80. This is necessary so users can reach your website.
- **ECS Task Security Group:** LOCKED DOWN. It **only** allows traffic from the *ALB Security Group* on Port 3000.
- **Benefit:** No one can bypass the Load Balancer to access your server directly.

### 4. ECS Task Definition
Think of this as the **"Blueprint"** for your application. It defines:
- Which Docker image to use (e.g., your Express App image).
- How much CPU (e.g., 256 units) and Memory (e.g., 512 MiB) to allocate.
- Which ports to map (Port 3000).
- Logging configuration (sending logs to AWS CloudWatch).

### 5. ECS Service
Think of this as the **"Manager"**.
- It uses the *Task Definition* (blueprint) to launch instances of your app.
- **Desired Count:** If you set this to 2, the Service ensures exactly 2 containers are running at all times.
- **Auto-Healing:** If a container crashes, the Service detects it and immediately starts a fresh replacement to maintain the desired count.

---

## Step-by-Step Guide for Beginners

### 1. Provision Infrastructure Using Terraform

#### Step 1. Configure Remote Backend (terraform/backend.tf)
```hcl
terraform {
  backend "s3" {
    bucket = "your-terraform-backend-bucket"
    key    = "state/ecs-ecr/terraform.tfstate"
    region = "us-east-1"
  }
}
````

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

  - Provisions the entire infrastructure (VPC, ALB, ECS cluster, task definitions, etc.)

-----

## Bash Script to Push Docker Image to ECR (scripts/push\_ecr.sh)

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
docker tag $REPO_NAME:$IMAGE_TAG $ACCOUNT_ID.dkr.ecr.$[REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG](https://REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG)
docker push $ACCOUNT_ID.dkr.ecr.$[REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG](https://REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG)
```

-----

## Python Script to Push Docker Image to ECR (scripts/push\_ecr.py)

```python
import boto3, subprocess

repo_name = "t2s-express-app"   # ECR repo name
region = "us-east-1"            # AWS region
image_tag = "latest"            # Image tag

ecr = boto3.client("ecr", region_name=region)
sts = boto3.client("sts")
account_id = sts.get_caller_identity()["Account"]
repo_uri = f"{account_id}.dkr.ecr.{region}[.amazonaws.com/](https://.amazonaws.com/){repo_name}"

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

-----

## Bash Script to Deploy Image to ECS (scripts/deploy\_ecs.sh)

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

-----

## Python Script to Deploy Image to ECS (scripts/deploy\_ecs.py)

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

-----

## Summary of Terraform Files

  - `main.tf`: The core file. Defines the **VPC, ALB, Security Groups**, ECS cluster, service, task definition, and IAM roles.
  - `variables.tf`: Defines reusable input variables (Region, App Name, CPU/Memory).
  - `terraform.tfvars`: **Source of Truth**. Contains the actual values (e.g., port 3000, 256 CPU) for your specific deployment.
  - `outputs.tf`: Displays useful output like the **Load Balancer URL (to access your app)** and ECR repo URI.
  - `backend.tf`: Defines remote S3 backend for storing Terraform state.

-----

## How to Run

```bash
# Terraform infra
cd terraform
terraform init
terraform apply
# COPY THE ALB_HOSTNAME output! Paste it in your browser to see your app.

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

-----

## Author

**Dr. Emmanuel Naweji (2025)** Cloud | DevOps | SRE | FinOps | AI Mentor  
GitHub: [Here2ServeU](https://github.com/Here2ServeU)
LinkedIn: [emmanuelnaweji](https://www.linkedin.com/in/ready2assist/)
Medium: [@here2serveyou](https://medium.com/@here2serveyou)  
Book a Free 30-Minute Consultation: [naweji.setmore.com](https://here4you.setmore.com/emmanuel)
