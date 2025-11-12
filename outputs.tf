output "ecs_cluster_name" {
  description = "The name of the ECS cluster."
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_names" {
  description = "A map of the names of the created ECS services."
  value       = { for k, v in aws_ecs_service.this : k => v.name }
}

output "security_group_id" {
  description = "The ID of the security group created for the services."
  value       = aws_security_group.service_sg.id
}

output "efs_file_system_id" {
  description = "The ID of the EFS file system, if created."
  value       = var.efs_enabled ? aws_efs_file_system.main[0].id : null
}