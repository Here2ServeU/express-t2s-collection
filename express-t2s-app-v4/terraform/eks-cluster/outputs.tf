output "region" {
  value       = var.region
  description = "AWS region"
}

output "cluster_name" {
  value       = module.eks.cluster_name
  description = "EKS cluster name"
}

output "ingress_nginx_hostname_hint" {
  value       = "Run: kubectl -n ingress-nginx get svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
  description = "Command to get the NGINX LB DNS"
}
