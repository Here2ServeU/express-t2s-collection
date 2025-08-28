##########################
# Root Modules Wiring
##########################

module "vpc" {
  source       = "./modules/vpc"
  cluster_name = var.cluster_name
  env          = var.env
  type         = var.type
  region       = var.region
  cidr_block   = var.vpc_cidr
}

module "security_groups" {
  source       = "./modules/security-groups"
  vpc_id       = module.vpc.vpc_id
  cluster_name = var.cluster_name
  env          = var.env
  type         = var.type
}

module "iam" {
  source = "./modules/iam"

  cluster_name = var.cluster_name
}

module "eks" {
  source = "./modules/eks"

  cluster_name               = var.cluster_name
  cluster_version            = var.cluster_version
  subnet_ids_private         = module.vpc.private_subnet_ids
  cluster_security_group_id  = module.security_groups.cluster_sg_id
  cluster_role_arn           = module.iam.cluster_role_arn
  node_role_arn              = module.iam.node_role_arn
  desired_size               = var.node_desired_size
  min_size                   = var.node_min_size
  max_size                   = var.node_max_size
  instance_types             = var.node_instance_types
  vpc_cni_version            = var.vpc_cni_version
  kube_proxy_version         = var.kube_proxy_version
}

# EKS cluster connection data (used to configure helm/k8s providers)
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

module "alb" {
  source = "./modules/alb"

  cluster_name              = module.eks.cluster_name
  region                    = var.region
  vpc_id                    = module.vpc.vpc_id
  oidc_provider_arn         = module.eks.oidc_provider_arn

  # Let this module use the helm/kubernetes providers configured above
  providers = {
    helm       = helm
    kubernetes = kubernetes
  }
}
