# Beginner2Mastery — Express Web App → EKS with ALB (Dev-Ready, Prod-Style)

This guide shows how to deploy the full stack (VPC, ECR, EKS, ALB Controller, Ingress) **using Terraform only**.  
By the end, your Dockerized Express.js app will run on AWS EKS, fronted by an AWS ALB.

---

## 0) Prereqs
- **CLI tools:** `aws`, `kubectl`, `terraform >= 1.3`, `helm`, `docker`, `jq`, `git`
- **AWS access:** IAM user/role with permissions for IAM, VPC, EKS, ECR, and ALB
- **Region:** defaults to `us-east-1`  

---

## 1) Remote State (Terraform Backend)
**Folder:** `terraform/backend`  
This module provisions (or references) the S3 bucket + DynamoDB table for Terraform remote state and locking.

```bash
cd terraform/backend
terraform init
terraform apply -auto-approve
```

> Make sure the same backend settings are used in `terraform/ecr` and `terraform/eks`.

---

## 2) ECR Repository + Push the Image
**Folder:** `terraform/ecr`

1. Provision the ECR repository:
```bash
cd ../../terraform/ecr
terraform init
terraform apply -auto-approve
```

2. Build & push the Docker image (uses `app/Dockerfile`):
```bash
bash build_and_push.sh
```

This prints an image URI like:
```
<ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/express-web-app:<TAG>
```

---

## 3) Provision the EKS Cluster + ALB Controller
**Folder:** `terraform/eks`

This module creates:
- VPC with public/private subnets + NAT  
- EKS cluster (managed node groups)  
- IAM roles for service accounts (IRSA)  
- AWS Load Balancer Controller via Helm  
- (Optional) Ingress-NGINX via Helm  

```bash
cd ../../terraform/eks
terraform init
terraform apply -auto-approve
```

---

## 4) Refresh kubeconfig for kubectl
After Terraform finishes, update your kubeconfig so kubectl points to the right cluster:

```bash
aws eks update-kubeconfig --region us-east-1 --name t2s-eks --alias t2s-eks
kubectl config use-context t2s-eks
```

Validate:
```bash
kubectl cluster-info
kubectl get nodes
```

---

## 5) Deploy the App
Update the image in `k8s/deployment.yaml` with your ECR image URI (from step 2). Then:

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
```

Check rollout:
```bash
kubectl -n apps get pods
kubectl -n apps get svc
kubectl -n ingress-nginx get svc
```

---

## 6) Get the ALB URL
List the ALB hostname created by the ingress:
```bash
kubectl -n ingress-nginx get svc ingress-nginx-controller
```

Look for the `EXTERNAL-IP` (DNS name). Open it in your browser:
```
http://<alb-dns>
```

---

## 7) Cleanup
1. Delete Kubernetes resources:
```bash
kubectl delete ns apps --ignore-not-found
```

2. Destroy infra (reverse order):
```bash
cd terraform/eks  && terraform destroy -auto-approve
cd ../ecr         && terraform destroy -auto-approve
# usually keep terraform/backend state infra
```

3. If Terraform destroy fails with **DependencyViolation** (common with ALBs, ENIs, IGWs), use:
```bash
chmod +x scripts/cleanup.sh
export FORCE_TERMINATE_INSTANCES=true
AWS_REGION=us-east-1 VPC_ID=<your-vpc-id> bash scripts/cleanup.sh
```

---

With this flow you can go **Dockerfile → ECR → EKS → ALB → cleanup** fully using Terraform + repo scripts.

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
