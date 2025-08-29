output "cluster_name"           { value = module.eks.cluster_name }
output "cluster_endpoint"       { value = module.eks.cluster_endpoint }
output "cluster_oidc_provider"  { value = module.eks.oidc_provider_arn }
output "vpc_id"                 { value = module.vpc.vpc_id }
output "public_subnet_ids"      { value = module.vpc.public_subnet_ids }
output "private_subnet_ids"     { value = module.vpc.private_subnet_ids }
output "alb_controller_role_arn"{ value = module.iam.alb_controller_role_arn }
