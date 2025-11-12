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

resource "aws_vpc_security_group_ingress_rule" "ingress" {
  for_each          = { for rule in var.ingress_rules : rule.description => rule }
  description       = each.value.description
  security_group_id = aws_security_group.service_sg.id
  cidr_ipv4         = each.value.cidr_ipv4
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  ip_protocol       = each.value.ip_protocol
}

resource "aws_vpc_security_group_egress_rule" "egress" {
  security_group_id = aws_security_group.service_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}