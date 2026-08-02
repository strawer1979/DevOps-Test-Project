terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40"
    }
  }
}

# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------
variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "domain_name" {
  description = "Root domain name (e.g., shopsimple.example.com)"
  type        = string
}

variable "primary_region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "secondary_region" {
  description = "Secondary AWS region for failover"
  type        = string
  default     = ""
}

variable "primary_alb_dns" {
  description = "DNS name of the primary ALB"
  type        = string
}

variable "primary_alb_zone_id" {
  description = "Canonical hosted zone ID of the primary ALB"
  type        = string
}

variable "secondary_alb_dns" {
  description = "DNS name of the secondary ALB (empty if single-region)"
  type        = string
  default     = ""
}

variable "secondary_alb_zone_id" {
  description = "Canonical hosted zone ID of the secondary ALB"
  type        = string
  default     = ""
}

variable "enable_failover" {
  description = "Enable active-passive failover routing"
  type        = bool
  default     = false
}

variable "health_check_path" {
  description = "Path for Route53 health checks"
  type        = string
  default     = "/health"
}

variable "health_check_port" {
  description = "Port for Route53 health checks"
  type        = number
  default     = 443
}

variable "tags" {
  type    = map(string)
  default = {}
}

# -----------------------------------------------------------------------------
# Hosted Zone
# -----------------------------------------------------------------------------
resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = merge(var.tags, {
    Name        = "${var.project}-${var.environment}-zone"
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

# -----------------------------------------------------------------------------
# Health Checks
# -----------------------------------------------------------------------------
resource "aws_route53_health_check" "primary" {
  fqdn              = var.primary_alb_dns
  port              = var.health_check_port
  type              = "HTTPS"
  resource_path     = var.health_check_path
  failure_threshold = 3
  request_interval  = 30

  tags = merge(var.tags, {
    Name        = "${var.project}-${var.environment}-primary-hc"
    Environment = var.environment
    Region      = var.primary_region
    ManagedBy   = "terraform"
  })
}

resource "aws_route53_health_check" "secondary" {
  count = var.enable_failover && var.secondary_alb_dns != "" ? 1 : 0

  fqdn              = var.secondary_alb_dns
  port              = var.health_check_port
  type              = "HTTPS"
  resource_path     = var.health_check_path
  failure_threshold = 3
  request_interval  = 30

  tags = merge(var.tags, {
    Name        = "${var.project}-${var.environment}-secondary-hc"
    Environment = var.environment
    Region      = var.secondary_region
    ManagedBy   = "terraform"
  })
}

# -----------------------------------------------------------------------------
# DNS Records
# -----------------------------------------------------------------------------

# Primary alias record
resource "aws_route53_record" "primary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.primary_alb_dns
    zone_id                = var.primary_alb_zone_id
    evaluate_target_health = true
  }

  # Failover routing: primary
  dynamic "failover_routing_policy" {
    for_each = var.enable_failover ? [1] : []
    content {
      type = "PRIMARY"
    }
  }

  # Simple routing (single region)
  dynamic "set_identifier" {
    for_each = var.enable_failover ? [] : [1]
    content {
      value = "simple"
    }
  }

  health_check_id = var.enable_failover ? aws_route53_health_check.primary.id : null
}

# Secondary alias record (failover target)
resource "aws_route53_record" "secondary" {
  count = var.enable_failover && var.secondary_alb_dns != "" ? 1 : 0

  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.secondary_alb_dns
    zone_id                = var.secondary_alb_zone_id
    evaluate_target_health = true
  }

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier = "${var.project}-${var.environment}-secondary"
}

# -----------------------------------------------------------------------------
# Regional subdomain records (explicit per-region access)
# -----------------------------------------------------------------------------
resource "aws_route53_record" "primary_regional" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "${var.primary_region}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.primary_alb_dns
    zone_id                = var.primary_alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "secondary_regional" {
  count = var.secondary_alb_dns != "" ? 1 : 0

  zone_id = aws_route53_zone.main.zone_id
  name    = "${var.secondary_region}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.secondary_alb_dns
    zone_id                = var.secondary_alb_zone_id
    evaluate_target_health = true
  }
}

# -----------------------------------------------------------------------------
# ACM Certificate (for HTTPS, must be in us-east-1 for CloudFront, but
# also provisioned in secondary region for ALB)
# -----------------------------------------------------------------------------
resource "aws_acm_certificate" "primary" {
  provider = aws

  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  tags = merge(var.tags, {
    Name        = "${var.project}-${var.environment}-cert-primary"
    Environment = var.environment
    Region      = var.primary_region
    ManagedBy   = "terraform"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# DNS validation for primary certificate
resource "aws_route53_record" "cert_validation_primary" {
  for_each = {
    for dvo in aws_acm_certificate.primary.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main.zone_id
}

resource "aws_acm_certificate_validation" "primary" {
  certificate_arn         = aws_acm_certificate.primary.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation_primary : record.fqdn]
}

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output "zone_id" {
  value = aws_route53_zone.main.zone_id
}

output "zone_name_servers" {
  value = aws_route53_zone.main.name_servers
}

output "primary_certificate_arn" {
  value = aws_acm_certificate.primary.arn
}

output "domain_name" {
  value = var.domain_name
}

output "primary_fqdn" {
  value = aws_route53_record.primary.fqdn
}

output "primary_regional_fqdn" {
  value = aws_route53_record.primary_regional.fqdn
}

output "secondary_regional_fqdn" {
  value = var.secondary_alb_dns != "" ? aws_route53_record.secondary_regional[0].fqdn : ""
}
