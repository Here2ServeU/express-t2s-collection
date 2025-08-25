# ───── Deployment Options ─────
region      = "us-east-1"
create_vpc  = false  # Set to true to auto-create VPC and subnets

# ───── Use Existing Network ─────
vpc_id      = "vpc-004194e2184e0d40d"
subnet_ids  = ["subnet-0acca018b1cc5f306", "subnet-0dcc65506b8690621"]

# ───── VPC Creation (if create_vpc = true) ─────
vpc_name         = "t2s-vpc"
vpc_cidr         = "10.0.0.0/16"
azs              = ["us-east-1a", "us-east-1b"]
private_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnets   = ["10.0.101.0/24", "10.0.102.0/24"]

# ───── EKS & App Config ─────
cluster_name    = "t2s-eks-cluster"
cluster_version = "1.29"
image_url       = "780593603882.dkr.ecr.us-east-1.amazonaws.com/t2s-express-app"
image_tag       = "latest"
container_name  = "t2s-container"
container_port  = 3000
