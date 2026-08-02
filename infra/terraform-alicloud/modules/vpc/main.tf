locals {
  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
    },
    var.tags
  )

  # Determine number of NAT gateways needed
  nat_gateway_count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0

  # EIP count matches NAT gateway count
  eip_count = local.nat_gateway_count
}

# VPC
resource "alicloud_vpc" "this" {
  cidr_block = var.vpc_cidr
  vpc_name   = "${var.project}-${var.environment}-vpc"

  tags = local.common_tags
}

# Public VSwitches
resource "alicloud_vswitch" "public" {
  count = length(var.public_vswitch_cidrs)

  vpc_id       = alicloud_vpc.this.id
  cidr_block   = var.public_vswitch_cidrs[count.index]
  zone_id      = var.availability_zones[count.index]
  vswitch_name = "${var.project}-${var.environment}-public-${count.index + 1}"

  tags = local.common_tags
}

# Private VSwitches
resource "alicloud_vswitch" "private" {
  count = length(var.private_vswitch_cidrs)

  vpc_id       = alicloud_vpc.this.id
  cidr_block   = var.private_vswitch_cidrs[count.index]
  zone_id      = var.availability_zones[count.index]
  vswitch_name = "${var.project}-${var.environment}-private-${count.index + 1}"

  tags = local.common_tags
}

# Database VSwitches
resource "alicloud_vswitch" "database" {
  count = length(var.database_vswitch_cidrs)

  vpc_id       = alicloud_vpc.this.id
  cidr_block   = var.database_vswitch_cidrs[count.index]
  zone_id      = var.availability_zones[count.index]
  vswitch_name = "${var.project}-${var.environment}-database-${count.index + 1}"

  tags = local.common_tags
}

# NAT Gateways
resource "alicloud_nat_gateway" "this" {
  count = local.nat_gateway_count

  vpc_id           = alicloud_vpc.this.id
  nat_gateway_name = var.single_nat_gateway ? "${var.project}-${var.environment}-nat" : "${var.project}-${var.environment}-nat-${count.index + 1}"
  spec             = "Small"
  vswitch_id       = alicloud_vswitch.public[var.single_nat_gateway ? 0 : count.index].id

  tags = local.common_tags
}

# EIP Addresses for NAT Gateways
resource "alicloud_eip_address" "this" {
  count = local.eip_count

  address_name         = var.single_nat_gateway ? "${var.project}-${var.environment}-eip" : "${var.project}-${var.environment}-eip-${count.index + 1}"
  internet_charge_type = "PayByTraffic"
  tags                 = local.common_tags
}

# EIP Associations
resource "alicloud_eip_association" "this" {
  count = local.eip_count

  instance_id   = alicloud_eip_address.this[count.index].id
  instance_type = "Nat"
  vswitch_id    = alicloud_vswitch.public[var.single_nat_gateway ? 0 : count.index].id
}

# SNAT Entries for Private Subnets
resource "alicloud_snat_entry" "private" {
  count = var.enable_nat_gateway ? length(var.private_vswitch_cidrs) : 0

  snat_table_id     = alicloud_nat_gateway.this[var.single_nat_gateway ? 0 : index(var.availability_zones, var.availability_zones[count.index])].id
  source_vswitch_id = alicloud_vswitch.private[count.index].id
  snat_ip           = alicloud_eip_address.this[var.single_nat_gateway ? 0 : index(var.availability_zones, var.availability_zones[count.index])].ip_address
}

# SNAT Entries for Database Subnets
resource "alicloud_snat_entry" "database" {
  count = var.enable_nat_gateway ? length(var.database_vswitch_cidrs) : 0

  snat_table_id     = alicloud_nat_gateway.this[var.single_nat_gateway ? 0 : index(var.availability_zones, var.availability_zones[count.index])].id
  source_vswitch_id = alicloud_vswitch.database[count.index].id
  snat_ip           = alicloud_eip_address.this[var.single_nat_gateway ? 0 : index(var.availability_zones, var.availability_zones[count.index])].ip_address
}

# Default Security Group
resource "alicloud_security_group" "default" {
  name        = "${var.project}-${var.environment}-sg"
  description = "Default security group for ${var.project}-${var.environment}"
  vpc_id      = alicloud_vpc.this.id

  tags = local.common_tags
}

# Security Group Rule: Allow all internal traffic
resource "alicloud_security_group_rule" "internal" {
  count = 1

  type              = "ingress"
  ip_protocol       = "all"
  policy            = "Accept"
  port_range        = "-1/-1"
  security_group_id = alicloud_security_group.default.id
  cidr_ip           = var.vpc_cidr
  description       = "Allow all internal traffic"
}

# Security Group Rule: Allow all outbound traffic
resource "alicloud_security_group_rule" "egress" {
  count = 1

  type              = "egress"
  ip_protocol       = "all"
  policy            = "Accept"
  port_range        = "-1/-1"
  security_group_id = alicloud_security_group.default.id
  cidr_ip           = "0.0.0.0/0"
  description       = "Allow all outbound traffic"
}
