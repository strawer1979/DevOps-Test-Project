locals {
  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
    },
    var.tags
  )

  instance_name  = "${var.project}-${var.environment}-redis"
  redis_password = var.password != "" ? var.password : random_password.redis_password.result
}

# Generate random password for Redis if not provided
resource "random_password" "redis_password" {
  count = var.password != "" ? 0 : 1

  length  = 16
  special = true
  lower   = true
  upper   = true
  number  = true
}

# Redis Instance
resource "alicloud_kvstore_instance" "this" {
  instance_class = var.instance_class
  instance_type  = var.instance_type
  engine_version = var.engine_version

  instance_name = local.instance_name
  vswitch_id    = var.vswitch_id

  # HA configuration
  node_type   = var.node_type
  shard_count = var.shard_count

  # Security
  password     = local.redis_password
  security_ips = ["172.16.0.0/12"] # Allow VPC internal access

  # Tags
  tags = local.common_tags
}

# Redis Connection
resource "alicloud_kvstore_connection" "this" {
  instance_id       = alicloud_kvstore_instance.this.id
  connection_string = "${var.project}-${var.environment}-redis"
  port              = "6379"
}

# Security Group for Redis
resource "alicloud_security_group" "redis" {
  name        = "${var.project}-${var.environment}-redis-sg"
  description = "Security group for Redis ${var.project}-${var.environment}"
  vpc_id      = var.vpc_id
  tags        = local.common_tags
}

# Security Group Rule: Allow Redis from VPC
resource "alicloud_security_group_rule" "redis_ingress" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "Accept"
  port_range        = "6379/6379"
  security_group_id = alicloud_security_group.redis.id
  cidr_ip           = "172.16.0.0/12"
  description       = "Allow Redis from VPC"
}

# Security Group Rule: Allow from allowed security groups
resource "alicloud_security_group_rule" "redis_ingress_sg" {
  count = length(var.allowed_security_group_ids) > 0 ? 1 : 0

  type                     = "ingress"
  ip_protocol              = "tcp"
  policy                   = "Accept"
  port_range               = "6379/6379"
  security_group_id        = alicloud_security_group.redis.id
  source_security_group_id = var.allowed_security_group_ids[0]
  description              = "Allow Redis from allowed security groups"
}
