terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.40" }
  }
}

variable "project" { type = string }
variable "environment" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener (empty for HTTP only)"
  type        = string
  default     = ""
}
variable "internal" {
  type    = bool
  default = false
}
variable "target_groups" {
  description = "Target groups to create"
  type = map(object({
    port                 = number
    protocol             = optional(string, "HTTP")
    target_type          = optional(string, "ip")
    path_pattern         = string
    health_check_path    = optional(string, "/health")
    health_check_port    = optional(string, "traffic-port")
    deregistration_delay = optional(number, 30)
    slow_start           = optional(number, 30)
  }))
  default = {
    frontend = {
      port              = 80
      path_pattern      = "/*"
      health_check_path = "/health"
    }
    api = {
      port              = 4000
      path_pattern      = "/api/*"
      health_check_path = "/health"
    }
  }
}
variable "tags" {
  type    = map(string)
  default = {}
}

resource "aws_security_group" "alb" {
  name_prefix = "${var.project}-${var.environment}-alb-"
  vpc_id      = var.vpc_id
  description = "ALB security group"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name        = "${var.project}-${var.environment}-alb-sg"
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  lifecycle { create_before_destroy = true }
}

resource "aws_lb" "this" {
  name               = "${var.project}-${var.environment}-alb"
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids

  enable_deletion_protection = var.environment == "prod"
  drop_invalid_header_fields = true

  access_logs {
    enabled = var.environment == "prod" || var.environment == "staging"
    bucket  = var.environment == "prod" ? "${var.project}-prod-alb-logs" : ""
    prefix  = "alb"
  }

  tags = merge(var.tags, {
    Name        = "${var.project}-${var.environment}-alb"
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

# Default target group (required by ALB)
resource "aws_lb_target_group" "default" {
  name_prefix = "default"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/health"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }

  tags = merge(var.tags, {
    Name        = "${var.project}-${var.environment}-default-tg"
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  lifecycle { create_before_destroy = true }
}

# Application target groups
resource "aws_lb_target_group" "app" {
  for_each = var.target_groups

  name_prefix = substr(each.key, 0, 6)
  port        = each.value.port
  protocol    = each.value.protocol
  vpc_id      = var.vpc_id
  target_type = each.value.target_type

  deregistration_delay = each.value.deregistration_delay
  slow_start           = each.value.slow_start

  health_check {
    path                = each.value.health_check_path
    port                = each.value.health_check_port
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 15
    matcher             = "200"
  }

  tags = merge(var.tags, {
    Name        = "${var.project}-${var.environment}-${each.key}-tg"
    Environment = var.environment
    Service     = each.key
    ManagedBy   = "terraform"
  })

  lifecycle { create_before_destroy = true }
}

# HTTP listener (redirect to HTTPS if certificate provided)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = var.certificate_arn != "" ? "redirect" : "forward"

    dynamic "redirect" {
      for_each = var.certificate_arn != "" ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    target_group_arn = var.certificate_arn != "" ? null : aws_lb_target_group.default.arn
  }

  tags = merge(var.tags, { ManagedBy = "terraform" })
}

# HTTPS listener (only if certificate provided)
resource "aws_lb_listener" "https" {
  count = var.certificate_arn != "" ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.default.arn
  }

  tags = merge(var.tags, { ManagedBy = "terraform" })
}

# Routing rules
resource "aws_lb_listener_rule" "app" {
  for_each = var.target_groups

  listener_arn = var.certificate_arn != "" ? aws_lb_listener.https[0].arn : aws_lb_listener.http.arn
  priority     = index(keys(var.target_groups), each.key) + 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app[each.key].arn
  }

  condition {
    path_pattern {
      values = [each.value.path_pattern]
    }
  }

  tags = merge(var.tags, { ManagedBy = "terraform" })
}

output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "alb_arn" {
  value = aws_lb.this.arn
}

output "alb_zone_id" {
  value = aws_lb.this.zone_id
}

output "target_group_arns" {
  value = { for k, tg in aws_lb_target_group.app : k => tg.arn }
}

output "security_group_id" {
  value = aws_security_group.alb.id
}

output "http_listener_arn" {
  value = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  value = var.certificate_arn != "" ? aws_lb_listener.https[0].arn : null
}
