locals {
  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
    },
    var.tags
  )

  instance_name = "${var.project}-${var.environment}-slb"
  address_type  = var.internal ? "intranet" : "internet"
}

# SLB Load Balancer
resource "alicloud_slb_load_balancer" "this" {
  load_balancer_name = local.instance_name
  address_type       = local.address_type
  vswitch_id         = var.internal ? var.vswitch_id : null
  load_balancer_spec = var.spec

  tags = local.common_tags
}

# SLB Server Groups (one for each target group)
resource "alicloud_slb_server_group" "this" {
  count = length(var.target_groups)

  name = "${local.instance_name}-${keys(var.target_groups)[count.index]}"

  # Note: Server group needs to be associated with a VServer group
  # The server group is created in the VPC
}

# HTTP Listener on port 80
resource "alicloud_slb_listener" "http" {
  load_balancer_id  = alicloud_slb_load_balancer.this.id
  listener_port     = 80
  listener_protocol = "http"
  backend_port      = 80
  bandwidth         = var.internal ? -1 : 10 # -1 for unlimited on internal

  health_check {
    enabled   = true
    interval  = 2
    timeout   = 5
    http_code = "http_2xx,http_3xx"
    path      = "/health"
    port      = 80
  }

  sticky_session {
    enabled = false
  }
}

# HTTPS Listener on port 443 (if certificate provided)
resource "alicloud_slb_listener" "https" {
  count = var.certificate_id != "" ? 1 : 0

  load_balancer_id   = alicloud_slb_load_balancer.this.id
  listener_port      = 443
  listener_protocol  = "https"
  backend_port       = 443
  bandwidth          = var.internal ? -1 : 10
  ssl_certificate_id = var.certificate_id

  health_check {
    enabled   = true
    interval  = 2
    timeout   = 5
    http_code = "http_2xx,http_3xx"
    path      = "/health"
    port      = 443
  }

  sticky_session {
    enabled = false
  }
}

# Rules for path-based routing (if multiple target groups)
resource "alicloud_slb_rule" "this" {
  count = length(var.target_groups) > 1 ? length(var.target_groups) : 0

  load_balancer_id = alicloud_slb_load_balancer.this.id
  listener_port    = 80
  server_group_id  = alicloud_slb_server_group.this[count.index].id

  # Path-based routing rule
  rule_name = "${keys(var.target_groups)[count.index]}-rule"
  domain    = "*"
  url       = var.target_groups[keys(var.target_groups)[count.index]].path
}

# Security Group for SLB (if internal)
resource "alicloud_security_group" "slb" {
  count = var.internal ? 1 : 0

  name        = "${var.project}-${var.environment}-slb-sg"
  description = "Security group for internal SLB ${var.project}-${var.environment}"
  vpc_id      = var.vpc_id
  tags        = local.common_tags
}

# Security Group Rule: Allow HTTP/HTTPS
resource "alicloud_security_group_rule" "slb_ingress" {
  count = var.internal ? 1 : 0

  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "Accept"
  port_range        = "80/443"
  security_group_id = alicloud_security_group.slb[0].id
  cidr_ip           = "172.16.0.0/12"
  description       = "Allow HTTP/HTTPS from VPC"
}
