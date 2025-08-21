# Express T2S App Monorepo

## Overview

This repository is the monorepo for the evolving Express-based web applications that support the mission of **Transformed 2 Succeed (T2S)**. Each version (`v1`, `v2`, etc.) represents a progressive stage of the Node.js + Express app from MVP to a production-ready, cloud-native, DevOps-enabled platform.

Our long-term vision is to build a mentorship system that is:
- Containerized using Docker
- Deployed via Terraform on AWS (ECR, ECS, EKS)
- Monitored and observable
- Secured with IAM, WAF, and DevSecOps scanning
- Scalable, cost-efficient, and highly available

---

## Goals

- Containerize each app version using Docker
- Push container images to AWS ECR
- Deploy using Terraform with ECS and EKS
- Implement GitHub Actions for CI/CD
- Add observability and monitoring (Grafana, Prometheus, CloudWatch)
- Integrate DevSecOps (Trivy, Checkov)
- Enable secure, automated mentorship workflows

---

## Versions and Status

Each app version is built on DevOps principles and infrastructure-as-code:

- `express-t2s-app-v1`: Basic Node.js + Express app
- `express-t2s-app-v2`: Adds Docker support and CI pipeline structure
- `express-t2s-app-v3`: Includes AWS ECR, ECS and EKS deployment using Terraform
- `express-t2s-app-v4`: Helm Charts for package management on EKS
- `express-t2s-app-v5`: GitOps (ArgoCD), monitoring, and, observability stack
- `express-t2s-app-v6`: Adding security to our EKS cluster (DevSecOps)
- `express-t2s-app-v7`: FinOps for Cost monitoring
- `express-t2s-app-v8`: SRE components are added to our Infra
- `express-t2s-app-v9`: Adds AI-based automation and intelligent monitoring

---

## Repo Structure

```
express-t2s-app/
├── express-t2s-app-v1/
│   ├── public/
│   └── index.js
│
├── express-t2s-app-v2/
│   ├── Dockerfile
│   └── .dockerignore
│
├── express-t2s-app-v3/
│   └── .github/workflows/ci.yml
│
├── express-t2s-app-v4/
│   ├── terraform/
│   │   ├── backend/
│   │   │   └── backend.tf
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── ...
│
├── express-t2s-app-v5/
├── express-t2s-app-
├── express-t2s-app-v6/v6/
└── README.md
```

---

## Remote Backend Setup

To enable collaborative and secure Terraform state management, each version uses an **S3 backend with DynamoDB locking**:

1. Manually create or bootstrap:
   - S3 bucket: `t2s-terraform-state`
   - DynamoDB table: `t2s-terraform-lock`

2. Add this to `terraform/backend/backend.tf` for the version:

```hcl
terraform {
  backend "s3" {
    bucket         = "t2s-terraform-state"
    key            = "express-t2s-app/<version>/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "t2s-terraform-lock"
    encrypt        = true
  }
}
```

3. Initialize Terraform backend:

```bash
cd terraform/backend
terraform init
```

---

## Local App Test (v1)

```bash
cd express-t2s-app-v1
npm install
node index.js
```

Visit: `http://localhost:3000`

---

## Cloud Deployment (v3+) - ECS Deployment

1. Ensure Docker image is built and pushed to ECR.
```bash
chmod +x build_and_push.sh
./build_and_push.sh
```

3. Navigate to the Terraform directory of the version:

```bash
cd express-t2s-app-v3/terraform
cd /ecr
```

3. Apply the Terraform deployment:

```bash
terraform init
terraform apply
```

4. Access the application using the output `load_balancer_dns` or domain name (ecs/eks).
- Accessing the App through ECS
```bash
# Find the Public IP of your ECS Task by running this command first:
aws ecs list-tasks \
  --cluster <your-cluster-name> \
  --service-name <your-service-name> \
  --query "taskArns[]" --output text

# Copy the Task ARN, then run the following command:
aws ecs describe-tasks \
  --cluster <your-cluster-name> \
  --tasks <your-task-arn> \
  --query "tasks[].attachments[].details[?name=='publicIPv4Address'].value" \
  --output text
```
- The above will output the Public IP.
- Test Access:
```bash
# On your browser or use the 'curl' command:
curl http://<public-ip>:3000
```
- If you cannot reach your Application over the browser. (1) Make sure your Security Group allows inbound TCP traffic on port 3000 from 0.0.0.0/0. (2) Make sure your app listens on 0.0.0.0, not localhost.

### Recommended (Use an Application Load Balancer)
- Using task public IPs directly is fragile (IP changes if the task restarts).

- Instead:
	•	Create an ALB in your VPC.
	•	Add a Target Group for port 3000.
	•	Attach the ECS service to the target group.
	•	Point a domain or use the ALB DNS name to access your app.

- A section on the Terraform scripts to deploy the Application behind an ALB, which gives you a single stable URL instead of chasing changing IPs. 

---
## Clean Up
```bash
# Deleting the Backend
cd ..                                        #To move up to express-t2s-app-v4/terraform
aws s3 rm s3://emmanuel-tf-state --recursive #To clean bucket via script (non-versioned only)
terraform destroy --auto-approve
```

- When using versioning, create a file and name it, delete_all_versions.py
- Add the following content ensuring you use your Bucket name:
```py
import boto3

bucket_name = "emmanuel-tf-state"
s3 = boto3.client("s3")

versions = s3.list_object_versions(Bucket=bucket_name)

for item in versions.get('Versions', []) + versions.get('DeleteMarkers', []):
    print(f"Deleting {item['Key']} (version: {item['VersionId']})")
    s3.delete_object(Bucket=bucket_name, Key=item['Key'], VersionId=item['VersionId'])
```
-Run the following commands: 
```bash
python3 -m venv venv
source venv/bin/activate
pip install boto3
python delete_all_versions.py
deactivate
rm -rf venv/
```

# Deleting the other Resources
```
cd ecr (or ecs)
terraform destroy --auto-approve
```

---

## Cloud Deployment (v3+) - Step-by-Step Deploying Express App on EKS

### 1. Clone and navigate to the Terraform folder
```bash
cd express-t2s-app/express-t2s-app-v6/terraform
```

### 2. Initialize and apply the Terraform configuration
```bash
terraform init
terraform apply -auto-approve
```

### 3. Configure kubectl to connect to your EKS cluster
```bash
aws eks --region <region> update-kubeconfig --name express-t2s-cluster
```

### 4. Build and Push Docker Image to ECR
```bash
cd ../../express-t2s-app-v2
docker build -t <aws_account_id>.dkr.ecr.<region>.amazonaws.com/express-t2s-app:latest .
aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.<region>.amazonaws.com
docker push <aws_account_id>.dkr.ecr.<region>.amazonaws.com/express-t2s-app:latest
```

### 5. Create image pull secret for EKS to access ECR
```bash
kubectl create secret docker-registry ecr-registry-secret \
--docker-server=<aws_account_id>.dkr.ecr.<region>.amazonaws.com \
--docker-username=AWS \
--docker-password=$(aws ecr get-login-password --region <region>)
```

### 6. Create Kubernetes Deployment and Service

📄 `deployment.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: express-t2s-deployment
  labels:
    app: express-t2s
spec:
  replicas: 2
  selector:
    matchLabels:
      app: express-t2s
  template:
    metadata:
      labels:
        app: express-t2s
    spec:
      containers:
        - name: express-t2s
          image: <aws_account_id>.dkr.ecr.<region>.amazonaws.com/express-t2s-app:latest
          ports:
            - containerPort: 3000
          resources:
            requests:
              cpu: '100m'
              memory: '128Mi'
            limits:
              cpu: '250m'
              memory: '256Mi'
          livenessProbe:
            httpGet:
              path: /
              port: 3000
            initialDelaySeconds: 10
            periodSeconds: 15
          readinessProbe:
            httpGet:
              path: /
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 10
      imagePullSecrets:
        - name: ecr-registry-secret
```

📄 `service.yaml`
```yaml
apiVersion: v1
kind: Service
metadata:
  name: express-t2s-service
  labels:
    app: express-t2s
spec:
  type: LoadBalancer
  selector:
    app: express-t2s
  ports:
    - protocol: TCP
      port: 80
      targetPort: 3000
```

Apply the files:
```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

### 7. Access the App Over the Internet
```bash
kubectl get svc express-t2s-service
```
Open the `EXTERNAL-IP` in your browser:
```
http://<external-ip>
```

---

## Final Outcome

By completing this monorepo series, we will achieve:
- Production-grade cloud infrastructure
- CI/CD & GitOps workflows
- Secure, observable applications
- Real-world DevOps portfolio experience

---

© 2025 Emmanuel Naweji. All rights reserved.
