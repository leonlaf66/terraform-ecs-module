variable "app_name" {
  description = "A name for the application, used to prefix resources."
  type        = string
}

variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC where resources will be deployed."
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs for the ECS services and EFS mount targets."
  type        = list(string)
}

variable "shared_ecr_repository_url" {
  description = "The URL of the shared ECR repository (e.g., 123.dkr.ecr/repo-name)."
  type        = string
}

variable "ecs_execution_role_arn" {
  description = "The ARN of the IAM role for ECS task execution."
  type        = string
}

variable "ecs_task_role_arn" {
  description = "The ARN of the IAM role for the ECS task itself."
  type        = string
  default     = null
}

variable "container_insights_enabled" {
  description = "Whether to enable Container Insights for the ECS cluster."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain logs in CloudWatch."
  type        = number
  default     = 30
}

variable "common_tags" {
  description = "A map of common tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "deployment_minimum_healthy_percent" {
  description = "The lower limit on the number of tasks that must remain running during a deployment."
  type        = number
  default     = 100
}

variable "deployment_maximum_percent" {
  description = "The upper limit on the number of tasks that can run during a deployment."
  type        = number
  default     = 200
}

variable "ingress_rules" {
  description = "A list of ingress rules for the security group."
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    ip_protocol = string
    cidr_ipv4   = string
  }))
  default = []
}

variable "efs_enabled" {
  description = "If true, creates an EFS filesystem for persistent storage."
  type        = bool
  default     = false
}

variable "services" {
  description = "A map of service configurations to deploy. The map key is the logical service name."
  type = map(object({

    image_tag     = string
    
    cpu           = number
    memory        = number
    port_mappings = list(object({ containerPort = number, hostPort = number, protocol = string }))
    environment   = optional(list(object({ name = string, value = string })), [])
    health_check = optional(object({
      command     = list(string)
      interval    = number
      timeout     = number
      retries     = number
      startPeriod = number
    }), null)

    desired_count    = optional(number, 1)
    assign_public_ip = optional(bool, false)

    efs_config = optional(object({
      path           = string
      container_path = string
    }), null)
  }))
  default = {}
}