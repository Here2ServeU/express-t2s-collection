# Express T2S App - Beginner-Friendly Guide (Version 2)

Welcome to the **T2S Express App** — an easy-to-follow project designed for complete beginners who want to learn how to build, package, and deploy a web application like a pro! This version is ideal even for those with no technical background.

## What Are We Building?

We’re building a simple web app using **Node.js** and **Express**, turning it into a **Docker container**, and deploying it to **Amazon Web Services (AWS)** using **ECR** and **Fargate/ECS**.

## Tools We’ll Use (Explained Simply)

- **Node.js + Express** – Makes your app run in the backend.
- **Docker** – Packages your app into a portable container.
- **AWS CLI** – Allows you to interact with AWS from your computer.
- **GitHub Actions** – Automates deployment when you push code.
- **Python/Bash/Terraform Scripts** – Help automate complex tasks step-by-step.

## Folder Structure

```
express-t2s-app-v2/
├── Dockerfile
├── index.js
├── package.json
├── scripts/
│   ├── push_to_ecr.py
│   └── push_to_ecr.sh
├── terraform/
│   ├── main.tf
│   └── variables.tf
└── README.md
```

## 1. Install Python

**Windows:**
- Visit https://www.python.org/downloads/windows/
- Download and install Python.
- During setup, make sure to check “Add Python to PATH”.

**Mac:**
- Open Terminal.
- Run: `brew install python`

## 2. Install and Configure AWS CLI

Install AWS CLI:
- Windows: https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-windows.html
- Mac: Run in Terminal: `brew install awscli`

Configure AWS CLI:
```bash
aws configure
```
You will enter:
- Your AWS access key
- Your secret key
- Your preferred region (e.g. `us-east-1`)

## 3. Build Docker Image

This command packages your app into a container:
```bash
docker build -t t2s-web-app .
```

## 4. Use Python Script to Push to AWS ECR

**File: `scripts/push_to_ecr.py`**
```python
import boto3
import subprocess

repo_name = "t2s-express-app"
region = "us-east-1"
image_tag = "latest"

ecr = boto3.client('ecr', region_name=region)
sts = boto3.client('sts')
account_id = sts.get_caller_identity()["Account"]
repo_uri = f"{account_id}.dkr.ecr.{region}.amazonaws.com/{repo_name}"

try:
    ecr.describe_repositories(repositoryNames=[repo_name])
except ecr.exceptions.RepositoryNotFoundException:
    ecr.create_repository(repositoryName=repo_name)

subprocess.run(f"aws ecr get-login-password --region {region} | docker login --username AWS --password-stdin {repo_uri}", shell=True, check=True)
subprocess.run(f"docker build -t {repo_name} .", shell=True, check=True)
subprocess.run(f"docker tag {repo_name}:{image_tag} {repo_uri}:{image_tag}", shell=True, check=True)
subprocess.run(f"docker push {repo_uri}:{image_tag}", shell=True, check=True)
```

Run the script:
```bash
python3 scripts/push_to_ecr.py
```

## 5. Use Bash Shell Script Instead

**File: `scripts/push_to_ecr.sh`**
```bash
#!/bin/bash
REPO_NAME=t2s-express-app
REGION=us-east-1
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
IMAGE_TAG=latest

aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

aws ecr describe-repositories --repository-names $REPO_NAME --region $REGION > /dev/null 2>&1
if [ $? -ne 0 ]; then
  aws ecr create-repository --repository-name $REPO_NAME --region $REGION
fi

docker build -t $REPO_NAME .
docker tag $REPO_NAME:$IMAGE_TAG $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG
```

Run it:
```bash
bash scripts/push_to_ecr.sh
```

## 6. Use Terraform to Create AWS ECR

**File: `terraform/main.tf`**
```hcl
provider "aws" {
  region = var.region
}

resource "aws_ecr_repository" "app" {
  name = var.repo_name
}
```

**File: `terraform/variables.tf`**
```hcl
variable "region" {
  description = "The AWS region to use"
}

variable "repo_name" {
  description = "The name of the ECR repository"
}

variable "account_id" {
  description = "Your AWS account ID"
}
```

Run it:
```bash
cd terraform/
terraform init
terraform apply
```

## Clean Up Docker

Stop containers:
```bash
docker ps
docker stop <container_id>
```

Remove stopped containers:
```bash
docker container prune
```

Remove unused images:
```bash
docker image prune
```

Remove everything:
```bash
docker system prune -a
```

## Python Virtual Environment

Create and activate environment:
```bash
python3 -m venv venv
source venv/bin/activate     # Mac/Linux
venv\Scripts\activate      # Windows
```

Deactivate:
```bash
deactivate
```

## Clean Up Terraform

Destroy all infrastructure:
```bash
terraform destroy
```

----

## Author

**Dr. Emmanuel Naweji (2025)**  
Cloud | DevOps | SRE | FinOps | AI Mentor  
GitHub: [Here2ServeU](https://github.com/Here2ServeU)
LinkedIn: [emmanuelnaweji](https://www.linkedin.com/in/ready2assist/) 
Medium: [@here2serveyou](https://medium.com/@here2serveyou)  
Book a Free 30-Minute Consultation: [naweji.setmore.com](https://here4you.setmore.com/emmanuel)
