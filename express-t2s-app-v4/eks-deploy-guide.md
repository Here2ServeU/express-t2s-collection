# EKS Cluster Creation with Terraform (Backend → ECR → EKS)

This short guide covers **only infrastructure creation** for your future Express Web App.  
You will:

1) Create a **remote Terraform backend** (S3 + DynamoDB)  
2) Create an **ECR private repository** and push your image  
3) Create an **EKS cluster** (networking, security, and cluster)  

No app is deployed yet—we’ll do that in the next version. At the end, you’ll also clean up to avoid costs.

---

## Prerequisites

- AWS CLI configured (`aws configure`) and an IAM identity with permissions for S3, DynamoDB, ECR, EC2, IAM, and EKS.
- Terraform v1.5+  
- Docker installed

Suggested repo layout:

```
terraform/
  backend/        # S3 state bucket + DynamoDB lock table
  ecr/            # ECR repository for app image
  eks-cluster/    # VPC + EKS + node group
scripts/
  build_and_push.sh
```

---

## 1) Remote Backend (S3 + DynamoDB)

**Goal:** Keep Terraform state in S3 and use DynamoDB for state locking.

#### Ensure you configure the following files as desired: 
- /terraform/ecr/backend.tf
- /terraform/ecr/variables.tf or terraform.tfvars (if necessary)

### A. Create the backend infra

```bash
cd terraform/backend
terraform init
terraform apply -auto-approve
```

Typical files you’ll have here:

- `main.tf` – creates S3 bucket and DynamoDB table (e.g., `t2s-terraform-states`, `tf-locks`)
- `outputs.tf` – prints bucket and table names (optional)
- `variables.tf` / `terraform.tfvars` – names, region, tags

> After this exists, other Terraform folders (like `ecr/` and `eks-cluster/`) can point their `backend.tf` to **this** S3 bucket + DynamoDB table.

---

## 2) ECR Private Repository (and push your image)

**Goal:** Create the private ECR repo and push one image tag (usually `latest`) that the cluster will use later.

#### Ensure you configure the following files as desired: 
- /terraform/ecr/backend.tf
- /terraform/ecr/variables.tf or terraform.tfvars (if necessary)

### A. Create the repo

```bash
cd ../ecr
terraform init
terraform apply -auto-approve
```

Typical files you’ll have here:

- `backend.tf` – points to the S3/DynamoDB you created in step 1  
- `main.tf` – creates the ECR repository (e.g., `t2s-express-app`) and optional lifecycle policy  
- `variables.tf` / `terraform.tfvars` – region, repo name, tags

### B. Build and push your image (single tag)

From repo root (or `scripts/`):

```bash
cd ../../scripts
chmod +x build_and_push.sh
# Usage: ./build_and_push.sh [REGION] [REPO_NAME] [TAG]
./build_and_push.sh us-east-1 t2s-express-app latest
```

What the script does:

- Ensures the ECR repo exists (if not already)
- Logs in to ECR
- Builds for `linux/amd64` (default) from `app/`
- Pushes **one** tag (for example `latest`) to ECR

> Keep the image architecture matched to your future nodes (for t3.* nodes, use `linux/amd64`).

---

## 3) EKS Cluster (Networking, Security, Cluster)

**Goal:** Provision a production-ready EKS cluster. We won’t deploy the app yet.

#### Ensure you configure the following files as desired: 
- /terraform/ecr/backend.tf
- /terraform/ecr/variables.tf or terraform.tfvars (if necessary)

```bash
cd ../terraform/eks-cluster
terraform init
terraform apply -auto-approve
```

What this Terraform does:

- **VPC & Subnets**: public/private subnets, NAT/IGW, routes  
- **IAM**: roles for EKS control plane and nodes; OIDC for IRSA  
- **EKS**: control plane (public+private endpoint as configured)  
- **Managed Node Group**: capacity settings (Spot or On-Demand), instance types, scaling

Notes:

- If you restrict the cluster public endpoint by CIDR, include your workstation’s IP (`admin_ip`) in variables, otherwise `kubectl` won’t reach the API later.
- Spot capacity may occasionally fail with `UnfulfillableCapacity`. If that happens, switch to `ON_DEMAND` or broaden `instance_types`.

We **do not** test connectivity yet because the application isn’t deployed in this version.

---

## Clean Up (to save money)

When you’re done, destroy in **reverse order**:

### 1) Destroy EKS cluster

```bash
cd terraform/eks-cluster
terraform destroy -auto-approve
```

Wait until all cluster resources (including load balancers, ENIs) are deleted.

### 2) Destroy ECR repository

```bash
cd ../ecr
# If the repo is not empty, empty or set "force_delete" in TF
terraform destroy -auto-approve
```

### 3) Destroy Backend (S3 + DynamoDB)

First **empty the S3 bucket** (required), then destroy:

```bash
aws s3 rm s3://<your-backend-bucket> --recursive
cd ../backend
terraform destroy -auto-approve
```

---

## Summary

- You created production-ready infrastructure for your future Express Web Application: **remote backend**, **ECR**, and an **EKS cluster**.
- You did **not** deploy the app yet—that will be the next version.
- You cleaned up the environment to avoid costs.

Next version: deploy the Express Web App to EKS, expose it to users over the internet, and add Helm for package management.

God bless you!

---

## Author

By Emmanuel Naweji, 2025  
**Cloud | DevOps | SRE | FinOps | AI Engineer**  
Helping businesses modernize infrastructure and guiding engineers into top 1% career paths through real-world projects and automation-first thinking.

![AWS Certified](https://img.shields.io/badge/AWS-Certified-blue?logo=amazonaws)
![Azure Solutions Architect](https://img.shields.io/badge/Azure-Solutions%20Architect-0078D4?logo=microsoftazure)
![CKA](https://img.shields.io/badge/Kubernetes-CKA-blue?logo=kubernetes)
![Terraform](https://img.shields.io/badge/IaC-Terraform-623CE4?logo=terraform)
![GitHub Actions](https://img.shields.io/badge/CI/CD-GitHub%20Actions-blue?logo=githubactions)
![GitLab CI](https://img.shields.io/badge/CI/CD-GitLab%20CI-FC6D26?logo=gitlab)
![Jenkins](https://img.shields.io/badge/CI/CD-Jenkins-D24939?logo=jenkins)
![Ansible](https://img.shields.io/badge/Automation-Ansible-red?logo=ansible)
![ArgoCD](https://img.shields.io/badge/GitOps-ArgoCD-orange?logo=argo)
![VMware](https://img.shields.io/badge/Virtualization-VMware-607078?logo=vmware)
![Linux](https://img.shields.io/badge/OS-Linux-black?logo=linux)
![FinOps](https://img.shields.io/badge/FinOps-Cost%20Optimization-green?logo=money)
![OpenAI](https://img.shields.io/badge/AI-OpenAI-ff9900?logo=openai)

---

## Connect with Me

- [LinkedIn](https://www.linkedin.com/in/ready2assist/)
- [GitHub](https://github.com/Here2ServeU)
- [Medium](https://medium.com/@here2serveyou)

---

## Book a Free Consultation

Let’s talk about modernizing your cloud infrastructure or DevOps strategy.  
👉🏾 [Schedule a free 1:1 consultation](https://bit.ly/letus-meet)
