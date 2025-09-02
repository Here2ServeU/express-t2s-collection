module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.8"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_irsa = true

  # Public + private endpoints, and restrict who can hit the public one
  cluster_endpoint_public_access       = true
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access_cidrs = var.admin_ip != "" ? ["${var.admin_ip}/32"] : ["0.0.0.0/32"]
  
  # (recommended) give the cluster creator admin in aws-auth
  enable_cluster_creator_admin_permissions = true
  
  eks_managed_node_group_defaults = {
    ami_type       = "AL2023_x86_64_STANDARD"
    instance_types = ["t3.medium"]
  }

  eks_managed_node_groups = {
    node_group = {
      desired_size  = 2
      min_size      = 1
      max_size      = 3
      capacity_type = "SPOT"
    }
  }

  tags = var.tags
}
