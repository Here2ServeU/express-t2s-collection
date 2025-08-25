
# Guide: Deploy Express App to AWS ECS using Terraform

This guide helps you deploy the Dockerized Express application from **express-t2s-app-v3** to **AWS ECS** using **Terraform**. This version assumes you already pushed the image to ECR (as completed in `v2`).

---

## Folder Structure

```
express-t2s-app-v3/
├── app/              # Express app source code (Node.js)
├── k8s/              # Kubernetes manifests (for EKS - covered in v5+)
├── scripts/          # Helper scripts (Bash, Python)
├── terraform/        # Terraform code for ECS cluster and app
```

---

## Prerequisites

Before you begin:

- Docker image pushed to ECR (`t2s-express-app:latest`)
- AWS CLI configured (`aws configure`)
- Terraform installed (`terraform -v`)
- Valid IAM permissions to create ECS, ALB, IAM roles, Security Groups, etc.
- S3 bucket + DynamoDB table created for remote backend

---

## Step-by-Step Deployment

### Step 1: Review Terraform Variables

Open `terraform/variables.tf` and make sure the following are updated:

```hcl
cluster_name   = "t2s-ecs-cluster"
service_name   = "t2s-express-service"
image_url      = "780593603882.dkr.ecr.us-east-1.amazonaws.com/t2s-express-app"
image_tag      = "latest"
vpc_id         = "vpc-xxxxxxxx"
subnet_ids     = ["subnet-xxxx", "subnet-yyyy"]
```

---

### Step 2: Initialize Terraform

```bash
cd terraform/ecs
terraform init
```

If using remote backend, confirm the S3 and DynamoDB config in `backend.tf`.

---

### Step 3: Plan Infrastructure

```bash
terraform plan
```

---

### Step 4: Apply and Deploy

```bash
terraform apply
```

This will:
- Create an ECS Cluster (Fargate)
- Launch a Task with the Express container from ECR
- Attach an Application Load Balancer (ALB)
- Configure Security Groups and IAM roles

---

## Verify Deployment

1. Go to [ECS Console](https://console.aws.amazon.com/ecs)
2. Open your cluster (`t2s-ecs-cluster`)
3. Confirm your service is running 2 tasks
4. Copy the ALB DNS name (from Terraform output)
5. Open it in a browser: http://<ALB-DNS>

---

## Cleanup Resources

To remove all deployed infrastructure:

```bash
terraform destroy
```

---

## Next Step

Deploy the Express App using EKS. 

---

© 2025 Emmanuel Naweji • Transformed 2 Succeed (T2S)
