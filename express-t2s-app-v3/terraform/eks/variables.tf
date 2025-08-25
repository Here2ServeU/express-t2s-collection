# ────────────────────────────────
# outputs.tf
# ────────────────────────────────
output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_kubeconfig" {
  value = module.eks.kubeconfig_filename
}

output "load_balancer_dns" {
  value = kubernetes_service.app.status[0].load_balancer[0].ingress[0].hostname
  description = "Public DNS of the ALB"
}
