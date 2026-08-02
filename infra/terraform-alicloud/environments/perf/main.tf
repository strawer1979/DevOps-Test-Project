# -----------------------------------------------------------------------------
# Perf Environment — ShopSimple (Alicloud)
# Multi-region: cn-hangzhou (primary) + ap-southeast-1 (secondary)
# -----------------------------------------------------------------------------

locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    CostCenter  = var.cost_center
  }
}

# -----------------------------------------------------------------------------
# VPC (Primary Region)
# -----------------------------------------------------------------------------
module "vpc" {
  source = "../../modules/vpc"

  project     = var.project
  environment = var.environment

  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# ACK (Alibaba Container Service for Kubernetes) - Primary Region
# -----------------------------------------------------------------------------
module "ack" {
  source = "../../modules/ack"

  project     = var.project
  environment = var.environment

  kubernetes_version     = var.kubernetes_version
  vpc_id                 = module.vpc.vpc_id
  private_vswitch_ids    = module.vpc.private_vswitch_ids
  public_vswitch_ids     = module.vpc.public_vswitch_ids
  node_pools             = var.ack_node_pools
  endpoint_public_access = true

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# RDS (PostgreSQL) - Primary Region Only
# -----------------------------------------------------------------------------
module "rds" {
  source = "../../modules/rds"

  project     = var.project
  environment = var.environment

  vpc_id                     = module.vpc.vpc_id
  vswitch_ids                = module.vpc.database_vswitch_ids
  allowed_security_group_ids = [module.ack.security_group_id]

  instance_type       = var.rds_instance_type
  high_availability   = var.rds_high_availability
  deletion_protection = var.rds_deletion_protection

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Redis - Primary Region Only
# -----------------------------------------------------------------------------
module "redis" {
  source = "../../modules/redis"

  project     = var.project
  environment = var.environment

  vpc_id                     = module.vpc.vpc_id
  vswitch_id                 = module.vpc.database_vswitch_ids[0]
  allowed_security_group_ids = [module.ack.security_group_id]

  instance_class = var.redis_instance_class
  node_type      = var.redis_node_type

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# OSS (Object Storage Service) - Primary Region
# -----------------------------------------------------------------------------
module "oss" {
  source = "../../modules/oss"

  project     = var.project
  environment = var.environment

  versioning = "Disabled"

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# ACR (Container Registry) - Primary Region
# -----------------------------------------------------------------------------
module "acr" {
  source = "../../modules/acr"

  project     = var.project
  environment = var.environment

  repo_type = "PUBLIC"

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# SLB (Server Load Balancer) - Primary Region Only
# -----------------------------------------------------------------------------
module "slb" {
  source = "../../modules/slb"

  project     = var.project
  environment = var.environment

  vpc_id         = module.vpc.vpc_id
  vswitch_id     = module.vpc.public_vswitch_ids[0]
  internal       = var.slb_internal
  certificate_id = var.certificate_id

  tags = local.common_tags
}

# =============================================================================
# Secondary Region Resources (ap-southeast-1)
# =============================================================================

# -----------------------------------------------------------------------------
# VPC - Secondary Region
# -----------------------------------------------------------------------------
module "vpc_secondary" {
  source = "../../modules/vpc"

  providers = {
    alicloud = alicloud.secondary
  }

  project     = var.project
  environment = var.environment

  vpc_cidr           = "172.32.0.0/12"
  availability_zones = ["ap-southeast-1a", "ap-southeast-1b"]
  enable_nat_gateway = true
  single_nat_gateway = true

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# ACK - Secondary Region
# -----------------------------------------------------------------------------
module "ack_secondary" {
  source = "../../modules/ack"

  providers = {
    alicloud = alicloud.secondary
  }

  project     = var.project
  environment = "${var.environment}-secondary"

  kubernetes_version     = var.kubernetes_version
  vpc_id                 = module.vpc_secondary.vpc_id
  private_vswitch_ids    = module.vpc_secondary.private_vswitch_ids
  public_vswitch_ids     = module.vpc_secondary.public_vswitch_ids
  node_pools             = var.ack_node_pools
  endpoint_public_access = true

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# ACR - Secondary Region
# -----------------------------------------------------------------------------
module "acr_secondary" {
  source = "../../modules/acr"

  providers = {
    alicloud = alicloud.secondary
  }

  project     = var.project
  environment = "${var.environment}-secondary"

  repo_type = "PUBLIC"

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# OSS - Secondary Region (Replication Target)
# -----------------------------------------------------------------------------
module "oss_secondary" {
  source = "../../modules/oss"

  providers = {
    alicloud = alicloud.secondary
  }

  project     = var.project
  environment = var.environment

  versioning = "Enabled"

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# SLB - Secondary Region
# -----------------------------------------------------------------------------
module "slb_secondary" {
  source = "../../modules/slb"

  providers = {
    alicloud = alicloud.secondary
  }

  project     = var.project
  environment = "${var.environment}-secondary"

  vpc_id         = module.vpc_secondary.vpc_id
  vswitch_id     = module.vpc_secondary.public_vswitch_ids[0]
  internal       = var.slb_internal
  certificate_id = var.certificate_id

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# DNS - Global Load Balancing with Failover
# -----------------------------------------------------------------------------
module "dns" {
  source = "../../modules/dns"

  project     = var.project
  environment = var.environment

  domain_name           = var.domain_name
  primary_region        = var.region
  secondary_region      = var.secondary_region
  primary_slb_address   = module.slb.slb_address
  secondary_slb_address = module.slb_secondary.slb_address
  enable_failover       = true

  tags = local.common_tags
}
