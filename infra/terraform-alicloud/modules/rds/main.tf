locals {
  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
    },
    var.tags
  )

  # Generate security IPs from VPC CIDR and allowed security groups
  # We'll use the VPC's primary CIDR block
  security_ips = concat(
    ["172.16.0.0/12"], # Default VPC CIDR - will be updated based on actual VPC
    var.allowed_security_group_ids
  )

  instance_name = "${var.project}-${var.environment}-rds"
}

# Generate random password for database
resource "random_password" "db_password" {
  length  = 16
  special = true
  lower   = true
  upper   = true
  number  = true
}

# Get VPC information for security group calculation
data "alicloud_vpc" "this" {
  id = var.vpc_id
}

# RDS Instance
resource "alicloud_db_instance" "this" {
  engine                   = var.engine
  engine_version           = var.engine_version
  instance_type            = var.instance_type
  instance_storage         = var.storage
  db_instance_storage_type = var.storage_type

  instance_name   = local.instance_name
  vswitch_id      = var.vswitch_ids[0]
  security_ips    = ["172.16.0.0/12"] # Allow VPC internal access
  connection_mode = "Standard"

  # High availability settings
  # Note: For high availability, need to set maintain_time and potentially zone_id
  maintain_time = "04:00Z-05:00Z"

  # Backup settings
  backup_time             = var.backup_time
  backup_retention_period = var.backup_retention_period

  # Protection
  deletion_protection = var.deletion_protection

  # SSL settings
  ssl_action = "Close"

  # Tags
  tags = local.common_tags

  # Dynamic zone configuration based on high_availability
  dynamic "zone_id" {
    for_each = var.high_availability ? [1] : []
    content {
      zone_id = var.vswitch_ids[0]
    }
  }
}

# Database Account
resource "alicloud_db_account" "this" {
  instance_id = alicloud_db_instance.this.id
  name        = var.db_username
  password    = random_password.db_password.result
  type        = "Normal"
  description = "Master account for ${var.db_name}"
}

# Database Connection
resource "alicloud_db_connection" "this" {
  instance_id              = alicloud_db_instance.this.id
  connection_string_prefix = "${var.project}-${var.environment}"
  port                     = "5432"
}

# Security Group for RDS
resource "alicloud_security_group" "rds" {
  name        = "${var.project}-${var.environment}-rds-sg"
  description = "Security group for RDS ${var.project}-${var.environment}"
  vpc_id      = var.vpc_id
  tags        = local.common_tags
}

# Security Group Rule: Allow PostgreSQL from VPC
resource "alicloud_security_group_rule" "rds_ingress" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "Accept"
  port_range        = "5432/5432"
  security_group_id = alicloud_security_group.rds.id
  cidr_ip           = "172.16.0.0/12"
  description       = "Allow PostgreSQL from VPC"
}

# Security Group Rule: Allow from allowed security groups
resource "alicloud_security_group_rule" "rds_ingress_sg" {
  count = length(var.allowed_security_group_ids) > 0 ? 1 : 0

  type                     = "ingress"
  ip_protocol              = "tcp"
  policy                   = "Accept"
  port_range               = "5432/5432"
  security_group_id        = alicloud_security_group.rds.id
  source_security_group_id = var.allowed_security_group_ids[0]
  description              = "Allow PostgreSQL from allowed security groups"
}
