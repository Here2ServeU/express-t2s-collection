##########################
# Modules
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
  source        = "./modules/iam"
  cluster_name  = var.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn  # wired after eks created via depends_on
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

  depends_on = [module.vpc, module.security_groups] # ensure VPC/SGs first
}

# Read AFTER cluster is created
data "aws_eks_cluster" "this" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "this" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
}

# Aliased providers pointed at the live cluster (no kubeconfig needed)
provider "kubernetes" {
  alias                  = "eks"
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
  load_config_file       = false
}

provider "helm" {
  alias = "eks"
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
    load_config_file       = false
  }
}

# ALB Controller (after cluster ready)
module "alb" {
  source = "./modules/alb"

  cluster_name      = module.eks.cluster_name
  region            = var.region
  vpc_id            = module.vpc.vpc_id
  oidc_provider_arn = module.eks.oidc_provider_arn

  providers = {
    helm       = helm.eks
    kubernetes = kubernetes.eks
  }

  depends_on = [module.eks, module.iam]
}
