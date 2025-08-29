# Guide: Deploy Express App on Amazon EKS with Terraform + ECR

This guide helps you deploy the containerized **Express App** (`express-t2s-app-v3`) on **Amazon EKS** using Terraform. The workflow provisions **ECR + EKS** with Terraform, builds & pushes the app image, and deploys Kubernetes manifests from the `k8s/` directory.  

---

## Prerequisites

Install and configure:

- [AWS CLI](https://docs.aws.amazon.com/cli/) (`aws configure`)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Terraform](https://developer.hashicorp.com/terraform/downloads) (v1.6+ recommended)
- [Docker](https://docs.docker.com/get-docker/)

Your IAM user/role must have permissions for **EKS, ECR, EC2, IAM, ELB, VPC, and S3**.

---

## Folder Structure

```text
express-t2s-collection/express-t2s-app-v3/eks/
└── terraform/eks/
    ├── backend.tf              # Remote backend (S3 + DynamoDB)
    ├── main.tf               # Wires all modules
    ├── variables.tf          # Root variables (must be configured)
    ├── outputs.tf
    ├── provider.tf
    ├── versions.tf
    └── modules/
        ├── vpc/
        ├── security-groups/
        ├── iam/
        ├── eks/
        ├── alb/
        └── ecr/              # (Optional) creates ECR repo for the app
```

---

## Step 1: Configure Terraform Variables

In `terraform/eks/variables.tf` or a new `terraform.tfvars` file, set:

```hcl
region             = "us-east-1"
cluster_name       = "t2s-eks-cluster"
cluster_version    = "1.27"

# Node group settings
node_instance_types = ["t3.medium"]
node_desired_size   = 2
node_min_size       = 1
node_max_size       = 3

# Add-on versions
vpc_cni_version     = "v1.18.0-eksbuild.1"
kube_proxy_version  = "v1.27.10-eksbuild.2"

# ECR repo name
ecr_repo_name       = "t2s-express-app"
```

**Important**: The backend is already configured in `terraform/backend/backend.tf` (S3 + DynamoDB). Replace bucket/table names before initializing.

---

## Step 2: Initialize and Apply Terraform

```bash
cd terraform/eks
terraform init
terraform plan
terraform apply -auto-approve
```

This will create:

- VPC, Subnets, Security Groups  
- IAM Roles for EKS and Nodes  
- EKS Cluster + Node Group  
- AWS Load Balancer Controller  
- ECR Repository (`t2s-express-app`)  

---

## Step 3: Build and Push Docker Image to ECR

After Terraform finishes, run this script to build, tag, and push the app:

```bash
#!/bin/bash

set -e

# Set working directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="${SCRIPT_DIR}/../../app"
AWS_REGION="us-east-1"
REPO_NAME="t2s-express-app"
IMAGE_TAG="latest"

# Validate app directory exists
if [ ! -d "$APP_DIR" ]; then
  echo "Error: Application directory not found at: $APP_DIR"
  exit 1
fi

# Get AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

# Compose ECR URI
ECR_URI="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}"

echo "Logging into AWS ECR..."
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_URI"

echo "Building Docker image from: $APP_DIR"
docker build -t "${REPO_NAME}:${IMAGE_TAG}" "$APP_DIR"

echo "Tagging Docker image"
docker tag "${REPO_NAME}:${IMAGE_TAG}" "${ECR_URI}:${IMAGE_TAG}"

echo "Pushing image to ECR: ${ECR_URI}:${IMAGE_TAG}"
docker push "${ECR_URI}:${IMAGE_TAG}"

echo "Image pushed successfully."
```

Save it as `scripts/push-to-ecr.sh` and run:

```bash
chmod +x scripts/push-to-ecr.sh
./scripts/push-to-ecr.sh
```

---

## Step 4: Deploy Express App to EKS

Update `k8s/express.yaml` with the ECR image URL:

```yaml
containers:
- name: express
  image: <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/t2s-express-app:latest
  ports:
  - containerPort: 3000
```

Apply the manifests:

```bash
kubectl apply -f k8s/
kubectl get pods
kubectl get svc
```

Copy the **EXTERNAL-IP** or DNS from the service and open it in your browser.

---

## Step 5: Access via AWS Load Balancer Controller

The **Ingress + ALB** setup is handled by the ALB controller. Verify:

```bash
kubectl get ingress
```

Or fetch the DNS from AWS:

```bash
aws elbv2 describe-load-balancers --region us-east-1 --query "LoadBalancers[].DNSName"
```

---

## Step 6: Cleanup

To remove all resources:

```bash
cd terraform/eks
terraform destroy
```

---

## Next Steps

- Automate image builds with **GitHub Actions**  
- Use **Helm charts** for deployment packaging  
- Add **Prometheus & Grafana** for observability  
- Introduce **ArgoCD** for GitOps  

---

© 2025 Dr Emmanuel Naweji • Transformed 2 Succeed (T2S)
