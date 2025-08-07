output "cluster_id" {
  description = "ECS Cluster ID"
  value       = aws_ecs_cluster.main.id
}

output "service_name" {
  description = "ECS Service name"
  value       = aws_ecs_service.app.name
}

output "task_definition_arn" {
  description = "ECS Task Definition ARN"
  value       = aws_ecs_task_definition.app.arn
}

output "security_group_id" {
  description = "Security Group ID for the service"
  value       = aws_security_group.ecs_sg.id
}

output "log_group" {
  description = "CloudWatch Logs group for the container"
  value       = aws_cloudwatch_log_group.ecs.name
}
