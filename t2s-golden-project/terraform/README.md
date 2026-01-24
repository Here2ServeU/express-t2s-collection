# Terraform (EKS + Argo CD) — T2S Skeleton

Provisions:
- VPC (public/private subnets + NAT)
- EKS (managed node group)
- Namespaces: dev/staging/prod
- Argo CD via Helm

## Prerequisites
- Terraform >= 1.6
- AWS credentials configured
- kubectl + helm installed
- Remote state bucket + DynamoDB lock table (recommended)

## Deploy
```bash
cd terraform
terraform init
terraform plan -var-file=terraform.tfvars.example
terraform apply -var-file=terraform.tfvars.example
```

## Apply GitOps Applications
1) Replace repoURL in gitops/environments/*/application.yaml
2) Apply:
```bash
kubectl apply -f ../gitops/environments/dev/application.yaml
kubectl apply -f ../gitops/environments/staging/application.yaml
kubectl apply -f ../gitops/environments/prod/application.yaml
```
