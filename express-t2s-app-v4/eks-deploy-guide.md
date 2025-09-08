# EKS Deploy Guide for Express App (Complete Beginner)

This guide walks you through deploying a Dockerized Express.js app to Amazon EKS using Terraform and AWS CLI.

---

## Prerequisites

- AWS CLI configured (`aws configure`)
- Docker installed
- Terraform installed
- kubectl installed
- IAM user/role with access to S3, ECR, EC2, IAM, VPC, and EKS

---

## 1. Set Up Terraform Remote State

In `eks-cluster/backend.tf`, you’ll find the S3 backend configuration. Make sure the S3 bucket exists:

```bash
aws s3 mb s3://t2s-terraform-states --region us-east-1
```

---

## 2. Deploy EKS Cluster

```bash
cd eks-cluster
terraform init
terraform apply -var-file="terraform.tfvars"
```

This provisions:
- VPC, Subnets
- Security Groups, IAM
- ALB infrastructure
- EKS cluster with managed node group

---

## 3. Configure `kubectl` Access to the Cluster

```bash
aws eks --region us-east-1 update-kubeconfig --name ascode-cluster
kubectl get nodes
```

You should see EKS nodes ready.

---

## 4. Build and Push the Express App to ECR

### Step 1: Create ECR repository (only once)
```bash
aws ecr create-repository --repository-name express-app
```

### Step 2: Run the push script
```bash
cd scripts
chmod +x push_to_ecr.sh
./push_to_ecr.sh express-app
```

> 📝 This builds the Docker image and pushes it to your AWS ECR registry.

---

## 5. Deploy App to EKS

### Step 1: Replace `<ECR_IMAGE_URI>` in `k8s/deployment.yaml` with your actual image URI:
```bash
# Example
123456789012.dkr.ecr.us-east-1.amazonaws.com/express-app:latest
```

### Step 2: Apply the Kubernetes manifests
```bash
cd k8s
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

---

## 6. Access Your App via LoadBalancer

### Get the ALB DNS:

```bash
kubectl get svc express-app-service
```

Look for the `EXTERNAL-IP` or `LoadBalancer Ingress`:

```bash
NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP                                                              PORT(S)
express-app-service    LoadBalancer   10.100.163.132   a12345678901234567890.elb.us-east-1.amazonaws.com   80:31823/TCP
```

### Open in your browser:

```bash
http://a12345678901234567890.elb.us-east-1.amazonaws.com
```

---

## Success!

You now have a fully running Express.js app deployed on a secure and scalable EKS cluster using Terraform and AWS best practices.


---

## Bonus Tips

- Use [Kubecost](https://www.kubecost.com/) to monitor EKS cost
- Use [Trivy](https://aquasecurity.github.io/trivy/) to scan your image
- Add a `HorizontalPodAutoscaler` for scaling---

## 7. Automate with GitHub Actions

You can use GitHub Actions to build, tag, and push your Docker image to ECR, and optionally deploy to EKS.

### Create `.github/workflows/deploy.yml` in your repo:

```yaml
name: Build and Deploy to ECR

on:
  push:
    branches:
      - main

env:
  AWS_REGION: us-east-1
  ECR_REPOSITORY: express-app

jobs:
  build-and-push:
    name: Build and Push Docker Image to ECR
    runs-on: ubuntu-latest

    permissions:
      id-token: write
      contents: read

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: arn:aws:iam::YOUR_AWS_ACCOUNT_ID:role/YOUR_GITHUB_ROLE
          aws-region: ${{ env.AWS_REGION }}

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: Build, Tag, and Push image to ECR
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        run: |
          IMAGE_TAG=$(echo $GITHUB_SHA | cut -c1-7)
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG ./app
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          echo "IMAGE=$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG" >> $GITHUB_ENV

  deploy:
    name: Deploy to EKS
    needs: build-and-push
    runs-on: ubuntu-latest

    steps:
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: arn:aws:iam::YOUR_AWS_ACCOUNT_ID:role/YOUR_GITHUB_ROLE
          aws-region: ${{ env.AWS_REGION }}

      - name: Update kubeconfig
        run: aws eks update-kubeconfig --region $AWS_REGION --name ascode-cluster

      - name: Deploy to Kubernetes
        run: |
          kubectl set image deployment/express-app express=${{ env.IMAGE }}
```

---

### Setup Steps

1. Replace `YOUR_AWS_ACCOUNT_ID` and `YOUR_GITHUB_ROLE` with your actual values
2. Create an OIDC IAM Role in AWS and allow GitHub to assume it
3. Push code to the `main` branch and watch it deploy!

---
