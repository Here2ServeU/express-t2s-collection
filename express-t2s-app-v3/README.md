# Express T2S App – Full DevOps Guide (Beginner Friendly)

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
  - push_to_ecr.sh               → Push Docker image to ECR (Bash)
  - deploy_to_ecs.sh             → Deploy Docker image to ECS (Bash)
  - push_and_deploy.sh           → Automates both Push & Deploy (Bash)
  - deploy_to_ecr_and_ecs.py     → Automates both Push & Deploy (Python)

- terraform/                     → Infrastructure-as-code using Terraform
  - main.tf                      → Defines Network, ALB, ECS cluster/service/task
  - backend.tf                   → Remote S3 backend for state management
  - variables.tf                 → Input variables for modularity
  - terraform.tfvars             → Actual values for variables
  - outputs.tf                   → Outputs like ALB DNS Name and ECR repo URL

---

## Infrastructure Deep Dive

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

*Note: Update the bucket name to one you have created in S3.*

#### Step 2. Initialize & Apply Terraform

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

*Tip: After applying, copy the `alb_hostname` from the outputs. This is the URL you will visit to see your app\!*

-----

## 2\. Build & Deploy (Automation Scripts)

We have provided both Bash and Python scripts to automate the process.

### Option A: Bash Scripts

**1. Push Image to ECR Only**

```bash
cd scripts
bash push_to_ecr.sh
```

*Builds the Docker image and pushes it to your ECR repository.*

**2. Deploy to ECS Only**

```bash
cd scripts
bash deploy_to_ecs.sh
```

*Forces the ECS Service to update and pull the latest image.*

**3. Full Push & Deploy (Recommended)**

```bash
cd scripts
bash push_and_deploy.sh
```

*Runs the entire workflow: Build -\> Push -\> Deploy.*

-----

### Option B: Python Scripts

If you prefer Python, use the all-in-one automation script:

**Full Push & Deploy**

```bash
cd scripts
python3 deploy_to_ecr_and_ecs.py
```

*Uses Boto3 to authenticate, build Docker image, push to ECR, and update the ECS service.*

-----

## Summary of Terraform Files

  - `main.tf`: The core file. Defines the **VPC, ALB, Security Groups**, ECS cluster, service, task definition, and IAM roles.
  - `variables.tf`: Defines reusable input variables (Region, App Name, CPU/Memory).
  - `terraform.tfvars`: **Source of Truth**. Contains the actual values (e.g., port 3000, 256 CPU) for your specific deployment.
  - `outputs.tf`: Displays useful output like the **Load Balancer URL** and ECR repo URI.
  - `backend.tf`: Defines remote S3 backend for storing Terraform state.

-----

## Author

**Dr. Emmanuel Naweji (2025)** Cloud | DevOps | SRE | FinOps | AI Mentor  
GitHub: [Here2ServeU](https://github.com/Here2ServeU)
LinkedIn: [emmanuelnaweji](https://www.linkedin.com/in/ready2assist/)
Medium: [@here2serveyou](https://medium.com/@here2serveyou)  
