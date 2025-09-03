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

  # Helpful tags for K8s (not ALB-specific)
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

  # Public endpoint on (you can restrict by CIDR if you want)
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  enable_irsa                                   = true
  enable_cluster_creator_admin_permissions      = true

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      desired_size   = 2
      min_size       = 1
      max_size       = 3
      capacity_type  = "SPOT"
    }
  }

  tags = var.tags
}

############################
# Bind K8s + Helm providers to the cluster
############################
data "aws_eks_cluster" "this" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

############################
# NGINX Ingress Controller (Helm)
############################
resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  namespace  = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.11.2"

  create_namespace = true

  # Service type LoadBalancer => AWS will create an ELB/NLB for the controller.
  # This is generic; no ALB controller needed.
  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  # (Optional) Keep the LB public
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
    value = "internet-facing"
  }

  # (Optional) Let targets be instance ports (works fine on EC2 nodes).
  # If you want IP mode, you'd typically need the AWS LB Controller (which we're avoiding).
  # So we don't set target-type=ip here.
}

############################
# Namespace for apps (just to be sure)
############################
resource "kubernetes_namespace_v1" "apps" {
  metadata {
    name = "apps"
  }
}
