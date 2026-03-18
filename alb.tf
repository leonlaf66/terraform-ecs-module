# ------------------------------------------------------------------------------
# Application Load Balancer  (created only when var.alb_enabled = true)
# ------------------------------------------------------------------------------

resource "aws_lb" "main" {
  count = var.alb_enabled ? 1 : 0

  name               = "${var.app_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg[0].id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = merge(var.common_tags, { Name = "${var.app_name}-alb" })
}

# HTTP listener — default action is a 404 fixed-response.
# Each service that declares alb_config will add its own forward rule below.
resource "aws_lb_listener" "http" {
  count = var.alb_enabled ? 1 : 0

  load_balancer_arn = aws_lb.main[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }

  tags = merge(var.common_tags, { Name = "${var.app_name}-http-listener" })
}

# One target group per service that opts in to ALB routing
resource "aws_lb_target_group" "this" {
  for_each = {
    for key, svc in var.services : key => svc
    if var.alb_enabled && svc.alb_config != null
  }

  name        = "${var.app_name}-${each.key}-tg"
  port        = each.value.alb_config.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip" # required for Fargate awsvpc networking

  health_check {
    enabled             = true
    path                = each.value.alb_config.health_check_path
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200-399"
  }

  deregistration_delay = 30

  tags = merge(var.common_tags, { Name = "${var.app_name}-${each.key}-tg" })
}

# One listener rule per service — path-based routing
resource "aws_lb_listener_rule" "this" {
  for_each = {
    for key, svc in var.services : key => svc
    if var.alb_enabled && svc.alb_config != null
  }

  listener_arn = aws_lb_listener.http[0].arn
  priority     = each.value.alb_config.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.key].arn
  }

  condition {
    path_pattern {
      values = each.value.alb_config.path_patterns
    }
  }

  tags = merge(var.common_tags, { Name = "${var.app_name}-${each.key}-rule" })
}
