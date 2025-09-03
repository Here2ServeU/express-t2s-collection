############################
# Provider
############################
provider "aws" {
  region = var.region
}

############################
# VPC
############################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.7"

  name            = var.name
  cidr            = var.vpc_cidr
  azs             = var.azs
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.name}" = "shared"
  }
  private_subnet_tags = {
    "kubernetes.io/cluster/${var.name}" = "shared"
  }

  tags = var.tags
}

############################
# EKS (managed node group)
############################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.8"

  cluster_name    = var.name
  cluster_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  enable_irsa                              = true
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      desired_size   = 2
      min_size       = 1
      max_size       = 3
    }
  }

  tags = var.tags
}

############################
# Configure k8s/helm providers AFTER EKS exists
############################
# Only keep auth data source and make it wait for the cluster
data "aws_eks_cluster_auth" "this" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

# IMPORTANT: Providers reference module.eks outputs,
# NOT the aws_eks_cluster data source (which causes your error)
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
  # Don't worry: provider is configured now but won't be used until resources below are enabled.
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

############################
# NGINX Ingress Controller (optional step 2)
############################
resource "helm_release" "ingress_nginx" {
  count           = var.enable_ingress ? 1 : 0
  name            = "ingress-nginx"
  namespace       = "ingress-nginx"
  repository      = "https://kubernetes.github.io/ingress-nginx"
  chart           = "ingress-nginx"
  version         = "4.11.2"
  create_namespace = true

  depends_on = [module.eks] # ensure EKS is ready

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
    value = "internet-facing"
  }
}

############################
# App namespace (optional step 2)
############################
resource "kubernetes_namespace_v1" "apps" {
  count = var.enable_ingress ? 1 : 0
  metadata { name = "apps" }
  depends_on = [module.eks]
}
