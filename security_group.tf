# ------------------------------------------------------------------------------
# ECS Service Security Group
# ------------------------------------------------------------------------------

resource "aws_security_group" "service_sg" {
  name        = "${var.app_name}-sg"
  description = "Security group for ${var.app_name} ECS services"
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.app_name}-sg"
    }
  )
}

# User-supplied ingress rules (e.g. direct debug access, Prometheus scrape, etc.)
resource "aws_vpc_security_group_ingress_rule" "ingress" {
  for_each          = { for rule in var.ingress_rules : rule.description => rule }
  description       = each.value.description
  security_group_id = aws_security_group.service_sg.id
  cidr_ipv4         = each.value.cidr_ipv4
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  ip_protocol       = each.value.ip_protocol
}

# When ALB is enabled, allow traffic from the ALB SG on each service's container port.
# This replaces any direct 0.0.0.0/0 ingress for those ports.
resource "aws_vpc_security_group_ingress_rule" "from_alb" {
  for_each = {
    for key, svc in var.services : key => svc
    if var.alb_enabled && svc.alb_config != null
  }

  security_group_id            = aws_security_group.service_sg.id
  referenced_security_group_id = aws_security_group.alb_sg[0].id
  from_port                    = each.value.alb_config.container_port
  to_port                      = each.value.alb_config.container_port
  ip_protocol                  = "tcp"
  description                  = "Allow traffic from ALB to ${each.key}"
}

resource "aws_vpc_security_group_egress_rule" "egress" {
  security_group_id = aws_security_group.service_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ------------------------------------------------------------------------------
# ALB Security Group  (created only when var.alb_enabled = true)
# ------------------------------------------------------------------------------

resource "aws_security_group" "alb_sg" {
  count = var.alb_enabled ? 1 : 0

  name        = "${var.app_name}-alb-sg"
  description = "Security group for ${var.app_name} ALB"
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.app_name}-alb-sg"
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  count = var.alb_enabled ? 1 : 0

  security_group_id = aws_security_group.alb_sg[0].id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "Allow HTTP from internet"
}

resource "aws_vpc_security_group_egress_rule" "alb_egress" {
  count = var.alb_enabled ? 1 : 0

  security_group_id = aws_security_group.alb_sg[0].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
