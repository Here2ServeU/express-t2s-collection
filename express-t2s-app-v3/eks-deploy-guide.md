# Guide: Deploy Express App on Amazon EKS using Terraform

This guide helps you deploy the containerized Express app in **express-t2s-app-v3** on Amazon EKS using Terraform. It assumes the image is already pushed to ECR.

---

## Prerequisites

Ensure you have the following installed and configured:

- AWS CLI (`aws configure`)
- kubectl (connected to EKS)
- eksctl
- Terraform (v1.3+ recommended)
- Docker (for local builds)
- An ECR repository with your app image (`t2s-express-app:latest`)
- Your IAM user must have the necessary permissions

---

## Folder Structure

```
express-t2s-app-v3/
├── app/
├── k8s/
├── scripts/
└── terraform/
```

---

## Step 1: Review and Configure Terraform for EKS

Navigate to the Terraform folder:

```bash
cd terraform/eks
```

Customize variables in `variables.tf` or use `terraform.tfvars` to set:

```hcl
region         = "us-east-1"
cluster_name   = "t2s-eks-cluster"
node_group     = "t2s-ng"
vpc_id         = "vpc-xxxxxx"
subnet_ids     = ["subnet-xxxxx1", "subnet-xxxxx2"]
image_url      = "AWS_Account_ID.dkr.ecr.us-east-1.amazonaws.com/t2s-express-app"
image_tag      = "latest"
container_port = 3000
```

---

## Step 2: Initialize and Apply Terraform

```bash
terraform init
terraform plan
terraform apply
```

This will:

- Create an EKS Cluster and Node Group
- Generate a `kubeconfig` file
- Deploy the Kubernetes resources

---

## Step 3: Verify EKS Deployment

After Terraform applies successfully:

```bash
kubectl get nodes
kubectl get pods
kubectl get svc
```

Then access the app using the LoadBalancer DNS from the `kubectl get svc` output.

---

## Step 4: Accessing the Application via ALB (AWS CLI or Console)

### Option A: AWS Console

1. Go to the [AWS EC2 Console – Load Balancers](https://console.aws.amazon.com/ec2/v2/home?#LoadBalancers)
2. Locate the ALB named `t2s-express-alb` (or the name defined in your variables)
3. Copy the **DNS name** (e.g., `t2s-express-alb-1234567890.us-east-1.elb.amazonaws.com`)
4. Open the DNS name in your browser

> Make sure your security group allows inbound traffic on port 80 (HTTP).

### Option B: AWS CLI

```bash
aws elbv2 describe-load-balancers   --names t2s-express-alb   --region us-east-1   --query "LoadBalancers[0].DNSName"   --output text
```

#### Or use it directly with curl:

```bash
curl http://$(aws elbv2 describe-load-balancers   --names t2s-express-alb   --region us-east-1   --query "LoadBalancers[0].DNSName"   --output text)
```

### Check Security Group Access (Optional)

```bash
aws ec2 describe-security-groups   --filters Name=group-name,Values=t2s-eks-sg   --region us-east-1   --query "SecurityGroups[0].IpPermissions"
```

Allow traffic if needed:

```bash
aws ec2 authorize-security-group-ingress   --group-name t2s-eks-sg   --protocol tcp   --port 80   --cidr 0.0.0.0/0   --region us-east-1
```

---

## Step 5: Cleanup (Destroy Resources)

To tear down the infrastructure when you're done:

```bash
terraform destroy
```

Confirm when prompted.

---

## Next Steps

To add monitoring and observability, proceed to **v4** or **v5**, where we introduce:

- GitHub Actions for CI/CD
- Helm Charts for package management
- Prometheus/Grafana for monitoring

---

© 2025 Emmanuel Naweji • Transformed 2 Succeed (T2S)
