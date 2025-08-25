# ────────────────────────────────
# 📁 main.tf
# ────────────────────────────────
provider "aws" {
  region = var.region
}

# Conditional networking
module "network" {
  count = var.create_vpc ? 1 : 0
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.2"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
}

# Get existing VPC and Subnets
data "aws_vpc" "existing" {
  count = var.create_vpc ? 0 : 1
  id    = var.vpc_id
}

data "aws_subnet" "existing" {
  count = var.create_vpc ? 0 : length(var.subnet_ids)
  id    = var.subnet_ids[count.index]
}

# EKS Cluster
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  subnets         = var.create_vpc ? module.network.private_subnets : var.subnet_ids
  vpc_id          = var.create_vpc ? module.network.vpc_id : var.vpc_id

  enable_irsa = true
  node_groups = {
    eks_nodes = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1

      instance_types = ["t3.medium"]
    }
  }
}

resource "kubernetes_deployment" "app" {
  metadata {
    name = "express-app"
    labels = {
      app = "express"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "express"
      }
    }

    template {
      metadata {
        labels = {
          app = "express"
        }
      }

      spec {
        container {
          image = "${var.image_url}:${var.image_tag}"
          name  = var.container_name

          port {
            container_port = var.container_port
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "app" {
  metadata {
    name = "express-service"
  }

  spec {
    type = "LoadBalancer"

    selector = {
      app = "express"
    }

    port {
      port        = 80
      target_port = var.container_port
    }
  }
}
