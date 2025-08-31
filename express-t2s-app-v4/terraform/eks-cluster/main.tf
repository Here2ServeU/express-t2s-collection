provider "aws" {
  region = var.region
}

module "vpc" {
  source = "../modules/vpc"

  name             = var.name
  region           = var.region
  vpc_cidr         = var.vpc_cidr
  azs              = var.azs
  public_subnets   = var.public_subnets
  private_subnets  = var.private_subnets
  intra_subnets    = var.intra_subnets
  tags             = var.tags
}

module "iam" {
  source = "../modules/iam"
  cluster_name = var.name
}

module "security_groups" {
  source = "../modules/security_groups"
  vpc_id = module.vpc.vpc_id
}

module "alb" {
  source = "../modules/alb"
  vpc_id = module.vpc.vpc_id
  public_subnets = module.vpc.public_subnets
}

module "eks" {
  source = "../modules/eks"

  cluster_name = var.name
  region       = var.region
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets
  node_group_instance_types = ["t3.large"]
  node_group_capacity_type  = "SPOT"
  tags = var.tags
}
