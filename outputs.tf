output "ecs_cluster_name" {
  description = "The name of the ECS cluster."
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_names" {
  description = "A map of the names of the created ECS services."
  value       = { for k, v in aws_ecs_service.this : k => v.name }
}

output "security_group_id" {
  description = "The ID of the security group created for the ECS services."
  value       = aws_security_group.service_sg.id
}

output "alb_security_group_id" {
  description = "The ID of the ALB security group, if created."
  value       = var.alb_enabled ? aws_security_group.alb_sg[0].id : null
}

output "alb_dns_name" {
  description = "The DNS name of the ALB, if created."
  value       = var.alb_enabled ? aws_lb.main[0].dns_name : null
}

output "alb_arn" {
  description = "The ARN of the ALB, if created."
  value       = var.alb_enabled ? aws_lb.main[0].arn : null
}

output "target_group_arns" {
  description = "A map of target group ARNs keyed by service name, if ALB is enabled."
  value = var.alb_enabled ? {
    for k, tg in aws_lb_target_group.this : k => tg.arn
  } : {}
}

output "efs_file_system_id" {
  description = "The ID of the EFS file system, if created."
  value       = var.efs_enabled ? aws_efs_file_system.main[0].id : null
}
