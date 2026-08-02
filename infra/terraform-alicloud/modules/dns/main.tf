terraform {
  required_version = ">= 1.5.0"
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "~> 1.230"
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
  description = "Primary Alicloud region"
  type        = string
  default     = "cn-hangzhou"
}

variable "secondary_region" {
  description = "Secondary Alicloud region for failover"
  type        = string
  default     = ""
}

variable "primary_slb_address" {
  description = "Public IP/address of the primary SLB"
  type        = string
}

variable "secondary_slb_address" {
  description = "Public IP/address of the secondary SLB (empty if single-region)"
  type        = string
  default     = ""
}

variable "enable_failover" {
  description = "Enable active-passive failover via DNS"
  type        = bool
  default     = false
}

variable "health_check_path" {
  description = "Path for health checks"
  type        = string
  default     = "/health"
}

variable "tags" {
  type    = map(string)
  default = {}
}

# -----------------------------------------------------------------------------
# DNS Domain
# -----------------------------------------------------------------------------
resource "alicloud_alidns_domain" "main" {
  domain_name = var.domain_name

  tags = merge(var.tags, {
    Name        = "${var.project}-${var.environment}-domain"
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

# -----------------------------------------------------------------------------
# DNS Records
# -----------------------------------------------------------------------------

# Primary A record (direct to SLB IP)
resource "alicloud_alidns_record" "primary" {
  domain_name = alicloud_alidns_domain.main.domain_name
  rr          = "@"
  type        = "A"
  value       = var.primary_slb_address
  ttl         = 600

  # Weight-based routing for multi-region
  dynamic "line" {
    for_each = var.enable_failover && var.secondary_slb_address != "" ? [] : [1]
    content {
      # Default line - all traffic goes to primary
    }
  }
}

# Secondary A record (for multi-region with weight-based routing)
resource "alicloud_alidns_record" "secondary" {
  count = var.enable_failover && var.secondary_slb_address != "" ? 1 : 0

  domain_name = alicloud_alidns_domain.main.domain_name
  rr          = "@"
  type        = "A"
  value       = var.secondary_slb_address
  ttl         = 600

  # Use different DNS line for secondary region
  line = "oversea" # Route overseas traffic to secondary
}

# -----------------------------------------------------------------------------
# Regional subdomain records (explicit per-region access)
# -----------------------------------------------------------------------------
resource "alicloud_alidns_record" "primary_regional" {
  domain_name = alicloud_alidns_domain.main.domain_name
  rr          = var.primary_region
  type        = "A"
  value       = var.primary_slb_address
  ttl         = 600
}

resource "alicloud_alidns_record" "secondary_regional" {
  count = var.secondary_slb_address != "" ? 1 : 0

  domain_name = alicloud_alidns_domain.main.domain_name
  rr          = var.secondary_region
  type        = "A"
  value       = var.secondary_slb_address
  ttl         = 600
}

# -----------------------------------------------------------------------------
# CNAME records for services
# -----------------------------------------------------------------------------
resource "alicloud_alidns_record" "api" {
  domain_name = alicloud_alidns_domain.main.domain_name
  rr          = "api"
  type        = "A"
  value       = var.primary_slb_address
  ttl         = 600
}

resource "alicloud_alidns_record" "www" {
  domain_name = alicloud_alidns_domain.main.domain_name
  rr          = "www"
  type        = "CNAME"
  value       = var.domain_name
  ttl         = 600
}

# -----------------------------------------------------------------------------
# Health Check (via Site Monitor)
# -----------------------------------------------------------------------------
resource "alicloud_cms_site_monitor" "primary_health" {
  address     = "https://${var.domain_name}${var.health_check_path}"
  task_name   = "${var.project}-${var.environment}-primary-hc"
  task_type   = "HTTP"
  interval    = 300
  description = "Health check for primary region ${var.primary_region}"

  options_json = jsonencode({
    method    = "GET"
    headers   = {}
    timeout   = 10
    frequency = 300
  })
}

resource "alicloud_cms_site_monitor" "secondary_health" {
  count = var.enable_failover && var.secondary_slb_address != "" ? 1 : 0

  address     = "https://${var.secondary_region}.${var.domain_name}${var.health_check_path}"
  task_name   = "${var.project}-${var.environment}-secondary-hc"
  task_type   = "HTTP"
  interval    = 300
  description = "Health check for secondary region ${var.secondary_region}"

  options_json = jsonencode({
    method    = "GET"
    headers   = {}
    timeout   = 10
    frequency = 300
  })
}

# -----------------------------------------------------------------------------
# SSL Certificate (via CAS - Certificate Authority Service)
# -----------------------------------------------------------------------------
# Note: In practice, certificates are managed via Alibaba Cloud CAS
# and referenced by ID in the SLB module. This module provides the
# DNS infrastructure for certificate validation.

# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------
output "domain_id" {
  value = alicloud_alidns_domain.main.id
}

output "domain_name" {
  value = alicloud_alidns_domain.main.domain_name
}

output "primary_record_id" {
  value = alicloud_alidns_record.primary.id
}

output "primary_regional_fqdn" {
  value = "${var.primary_region}.${var.domain_name}"
}

output "secondary_regional_fqdn" {
  value = var.secondary_slb_address != "" ? "${var.secondary_region}.${var.domain_name}" : ""
}

output "api_fqdn" {
  value = "api.${var.domain_name}"
}
