output "cluster_name" {
  value       = module.eks.cluster_name
  description = "EKS cluster name"
}

output "region" {
  value       = var.region
  description = "AWS region"
}

output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC id"
}
