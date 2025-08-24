
# T2S Express App – CI/CD with GitHub Actions, Docker, ECR, ECS

This guide explains how to set up Continuous Integration and Continuous Deployment (CI/CD) using GitHub Actions to build, tag, push your Dockerized Express app to Amazon ECR, and deploy it on ECS Fargate.

---

## CI/CD Concepts (Beginner Friendly)

### 1. What is CI?
Continuous Integration: Developers push code often, triggering automatic builds/tests.

### 2. What is CD?
Continuous Deployment: Automatically deploy approved builds to production or staging.

### 3. CI/CD in this project
- Docker image built from source
- Image pushed to AWS ECR
- ECS Service updated via GitHub Actions

---

## Real Example: Build & Deploy Express App

We will:
1. Build Docker image
2. Tag it
3. Push to ECR
4. Trigger ECS Deployment

---

## Prerequisites

- GitHub repo with your Express app + Dockerfile
- AWS account setup with:
  - ECR repository: `t2s-express-app`
  - ECS Cluster: `t2s-ecs-cluster`
  - ECS Service: `t2s-express-service`
  - IAM Role: `t2s-ecs-task-execution-role`
  - VPC: `vpc-004194e2184e0d40d`
  - Subnets: `subnet-0acca018b1cc5f306`, `subnet-0dcc65506b8690621`
  - Security Group: `t2s-ecs-sg`

### GitHub Secrets Required:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION` = `us-east-1`
- `ECR_REPOSITORY` = `t2s-express-app`
- `ECS_CLUSTER` = `t2s-ecs-cluster`
- `ECS_SERVICE` = `t2s-express-service`
- `CONTAINER_NAME` = `t2s-container`

---

## GitHub Actions Workflow (.github/workflows/deploy.yml)

```yaml
name: Build and Deploy to ECS

on:
  push:
    branches: [ "main" ]

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v3

    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ secrets.AWS_REGION }}

    - name: Login to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v1

    - name: Build, tag, and push image to ECR
      run: |
        IMAGE_TAG=$(date +%s)
        docker build -t ${{ secrets.ECR_REPOSITORY }}:$IMAGE_TAG .
        docker tag ${{ secrets.ECR_REPOSITORY }}:$IMAGE_TAG ${{ steps.login-ecr.outputs.registry }}/${{ secrets.ECR_REPOSITORY }}:$IMAGE_TAG
        docker push ${{ steps.login-ecr.outputs.registry }}/${{ secrets.ECR_REPOSITORY }}:$IMAGE_TAG
        echo "IMAGE_TAG=$IMAGE_TAG" >> $GITHUB_ENV

    - name: Deploy to Amazon ECS
      uses: aws-actions/amazon-ecs-deploy-task-definition@v1
      with:
        task-definition: ecs-task-def.json
        service: ${{ secrets.ECS_SERVICE }}
        cluster: ${{ secrets.ECS_CLUSTER }}
        wait-for-service-stability: true
        image: ${{ steps.login-ecr.outputs.registry }}/${{ secrets.ECR_REPOSITORY }}:${{ env.IMAGE_TAG }}
        container-name: ${{ secrets.CONTAINER_NAME }}
```

---

## ecs-task-def.json Example

```json
{
  "family": "t2s-express-task",
  "containerDefinitions": [
    {
      "name": "t2s-container",
      "image": "replace-this-later",
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
```

> GitHub Actions will automatically inject the new image during deploy.

---

## Summary

| Concept             | Description                                  |
|---------------------|----------------------------------------------|
| GitHub Actions      | Automates build and deploy workflows         |
| Docker              | Packages your app                            |
| ECR                 | Stores Docker images                         |
| ECS + Fargate       | Runs your containerized app                  |
| Terraform (optional)| Provisions your ECS resources                |

---

## Learning Tip

Validate locally before CI/CD:
```bash
docker build . -t t2s-app
docker run -p 3000:3000 t2s-app
aws ecr get-login-password | docker login ...
docker push <your-tag>
```

Then integrate GitHub Actions for full automation.

