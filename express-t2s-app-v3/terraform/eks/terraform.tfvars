# AWS Region
region = "us-east-1"

# EKS Cluster
cluster_name    = "t2s-eks-cluster"
cluster_version = "1.29"

# VPC (use existing)
vpc_id     = "vpc-004194e2184e0d40d"
subnet_ids = [
  "subnet-0acca018b1cc5f306", 
  "subnet-0dcc65506b8690621" 
]

# Optional – only used if create_vpc = true
create_vpc        = false
vpc_name          = "t2s-vpc"
vpc_cidr          = "145.0.0.0/16"
azs               = ["us-east-1a", "us-east-1b"]
private_subnets   = ["145.0.1.0/24", "145.0.2.0/24"]
public_subnets    = ["145.0.101.0/24", "145.0.102.0/24"]

# EKS Node Group settings
node_group_instance_types = ["t3.medium"]
node_group_desired_size   = 2
node_group_min_size       = 1
node_group_max_size       = 3

# IAM roles (auto-created if not reused)
cluster_role_name     = "t2s-eks-cluster-role"
node_group_role_name  = "t2s-eks-node-group-role"

# Container app deployment settings
container_name  = "t2s-container"
container_port  = 3000
image_url       = "780593603882.dkr.ecr.us-east-1.amazonaws.com/t2s-express-app"
image_tag       = "latest"
