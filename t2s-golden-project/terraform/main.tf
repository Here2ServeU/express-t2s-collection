module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  public_subnets  = var.public_subnet_cidrs
  private_subnets = var.private_subnet_cidrs

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = { Project = var.project_name }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${var.project_name}-eks"
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      instance_types = var.node_instance_types
      min_size       = var.node_min_size
      max_size       = var.node_max_size
      desired_size   = var.node_desired_size
    }
  }

  tags = { Project = var.project_name }
}

resource "kubernetes_namespace" "dev"     { metadata { name = "dev" } }
resource "kubernetes_namespace" "staging" { metadata { name = "staging" } }
resource "kubernetes_namespace" "prod"    { metadata { name = "prod" } }

resource "kubernetes_namespace" "argocd" { metadata { name = "argocd" } }

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = "6.7.18"

  set { name = "server.service.type", value = "LoadBalancer" }

  dynamic "set" {
    for_each = var.argocd_admin_password != "" ? [1] : []
    content {
      name  = "configs.secret.argocdServerAdminPassword"
      value = var.argocd_admin_password
    }
  }
}

/*
Next steps:
1) Replace repoURL placeholders in gitops/environments/*/application.yaml
2) Apply GitOps apps:
   kubectl apply -f ../gitops/environments/dev/application.yaml
*/
