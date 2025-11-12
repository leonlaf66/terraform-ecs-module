resource "aws_ecs_cluster" "main" {
  name = "${var.app_name}-cluster"

  setting {
    name  = "containerInsights"
    value = var.container_insights_enabled ? "enabled" : "disabled"
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.app_name}-cluster"
    }
  )
}

resource "aws_ecs_task_definition" "this" {
  for_each                 = var.services
  family                   = "${var.app_name}-${each.key}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  execution_role_arn       = var.ecs_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  dynamic "volume" {
    for_each = each.value.efs_config != null ? [1] : []
    content {
      name = "${each.key}-efs-storage"
      efs_volume_configuration {
        file_system_id     = aws_efs_file_system.main[0].id
        transit_encryption = "ENABLED"
        authorization_config {
          access_point_id = aws_efs_access_point.this[each.key].id
        }
      }
    }
  }

  container_definitions = jsonencode([
    {
      name      = "${var.app_name}-${each.key}-container"
      image     = "${var.shared_ecr_repository_url}:${each.value.image_tag}"
      essential = true
      portMappings = each.value.port_mappings
      mountPoints = each.value.efs_config != null ? [{
        containerPath = each.value.efs_config.container_path
        sourceVolume  = "${each.key}-efs-storage"
        readOnly      = false
      }] : []
      environment = each.value.environment
      healthCheck = each.value.health_check
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = each.key
        }
      }
    }
  ])

  tags = merge(
    var.common_tags,
    {
      Name = "${var.app_name}-${each.key}-task"
    }
  )
}

resource "aws_ecs_service" "this" {
  for_each                           = var.services
  name                               = "${var.app_name}-${each.key}-service"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.this[each.key].arn
  launch_type                        = "FARGATE"
  platform_version                   = "LATEST"
  enable_execute_command             = true
  desired_count                      = each.value.desired_count
  propagate_tags                     = "TASK_DEFINITION"
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent
  health_check_grace_period_seconds  = 60

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.service_sg.id]
    assign_public_ip = each.value.assign_public_ip
  }

  force_new_deployment = true

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.app_name}-${each.key}-service"
    }
  )
}

# Logging
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.app_name}"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.common_tags,
    {
      Name = "${var.app_name}-ecs-logs"
    }
  )
}