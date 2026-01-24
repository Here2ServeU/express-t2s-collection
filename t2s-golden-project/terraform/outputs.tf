output "cluster_name"     { value = module.eks.cluster_name }
output "cluster_endpoint" { value = module.eks.cluster_endpoint }
output "argocd_namespace" { value = kubernetes_namespace.argocd.metadata[0].name }
