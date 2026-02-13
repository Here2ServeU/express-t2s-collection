# Express Reliability Platform — Version 4 (ECS + CI/CD)

This repository represents **Version 4** of the Express Reliability Platform.

Version 4 focuses on:

- Cloud Orchestration using Amazon ECS (Fargate)
- Infrastructure as Code using Terraform
- CI/CD automation using GitHub Actions
- Real-world Bank (FinTech) and Hospital (Healthcare) simulation components

---

# Architecture Overview (V4)

Local Development → Docker Images → Amazon ECR → Amazon ECS (Fargate) → ALB → Public Endpoint  
GitHub Push → GitHub Actions → Build → Push → Deploy ECS

---

# Folder Structure

express-reliability-platform/
├── apps/
├── simulators/
├── infra/aws/ecs/
├── .aws/
├── .github/workflows/
├── docker-compose.yml
└── README.md

---

# Step 1 — Build & Push Images to ECR

export AWS_REGION="us-east-1"
export AWS_ACCOUNT_ID="123456789012"

aws ecr create-repository --repository-name node-api || true
aws ecr create-repository --repository-name flask-api || true

aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

docker build -t node-api:v1 apps/node-api
docker tag node-api:v1 $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/node-api:v1
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/node-api:v1

docker build -t flask-api:v1 apps/flask-api
docker tag flask-api:v1 $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/flask-api:v1
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/flask-api:v1

---

# Step 2 — Provision Infrastructure (Terraform)

cd infra/aws/ecs
terraform init
terraform apply

---

# Step 3 — CI/CD Pipeline (GitHub Actions)

Every push to main branch:
1) Builds Docker images
2) Pushes to ECR
3) Updates ECS task definitions
4) Deploys services

Required GitHub Secrets:
- AWS_REGION
- AWS_ACCOUNT_ID
- AWS_ROLE_TO_ASSUME
- ECS_CLUSTER_NAME
- ECS_NODE_SERVICE_NAME
- ECS_FLASK_SERVICE_NAME
- ECS_TASKDEF_NODE_PATH
- ECS_TASKDEF_FLASK_PATH

---

# Real-World Components

Bank:
- /bank/login
- /bank/balance
- /bank/transfer

Hospital:
- /hospital/checkin
- /hospital/vitals
- /hospital/med-order

Simulators generate load and stress conditions.

---

# Version 4 Outcome

You now have:
- ECS cluster
- Terraform-managed infra
- Automated CI/CD
- Real fintech + healthcare simulation
- Public cloud endpoint

Author: Emmanuel Naweji
