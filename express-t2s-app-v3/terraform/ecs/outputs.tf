output "ecs_cluster_name" {
  value = aws_ecs_cluster.t2s_cluster.name
}

output "ecs_service_name" {
  value = aws_ecs_service.t2s_service.name
}