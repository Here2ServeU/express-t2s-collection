module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.1"

  cluster_name                   = var.cluster_name
  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = { most_recent = true }
    kube-proxy = { most_recent = true }
    vpc-cni = { most_recent = true }
  }

  vpc_id                   = var.vpc_id
  subnet_ids               = var.subnet_ids
  control_plane_subnet_ids = var.control_plane_subnet_ids

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = var.node_group_instance_types
    attach_cluster_primary_security_group = true
  }

  eks_managed_node_groups = {
    "${var.cluster_name}-ng" = {
      min_size     = 1
      max_size     = 2
      desired_size = 1
      instance_types = var.node_group_instance_types
      capacity_type  = var.node_group_capacity_type

      tags = {
        Name = "${var.cluster_name}-ng"
      }
    }
  }

  tags = var.tags
}
