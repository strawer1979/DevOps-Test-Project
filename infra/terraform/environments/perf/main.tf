# -----------------------------------------------------------------------------
# Perf Environment — ShopSimple
# Multi-region: us-east-1 (primary) + ap-southeast-1 (secondary)
# Uses read replica in secondary region instead of multi-AZ
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
# PRIMARY REGION (us-east-1) Resources
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# VPC (Primary Region Only)
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
# EKS (Primary Region)
# -----------------------------------------------------------------------------
module "eks" {
  source = "../../modules/eks"

  project     = var.project
  environment = var.environment

  cluster_version        = var.cluster_version
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  public_subnet_ids      = module.vpc.public_subnet_ids
  node_groups            = var.eks_node_groups
  endpoint_public_access = true
  public_access_cidrs    = ["0.0.0.0/0"]

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# RDS (PostgreSQL - Primary Region Only)
# Uses read replica approach for DR
# -----------------------------------------------------------------------------
module "rds" {
  source = "../../modules/rds"

  project     = var.project
  environment = var.environment

  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.database_subnet_ids
  allowed_security_group_ids = [module.eks.cluster_security_group_id]

  instance_class      = var.rds_instance_class
  multi_az            = var.rds_multi_az
  deletion_protection = var.rds_deletion_protection
  skip_final_snapshot = true

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# ElastiCache (Redis - Primary Region Only)
# -----------------------------------------------------------------------------
module "elasticache" {
  source = "../../modules/elasticache"

  project     = var.project
  environment = var.environment

  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.database_subnet_ids
  allowed_security_group_ids = [module.eks.cluster_security_group_id]

  node_type          = var.redis_node_type
  num_cache_clusters = var.redis_num_cache_clusters

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# S3 (Product Images - Primary Region with Replication)
# -----------------------------------------------------------------------------
module "s3" {
  source = "../../modules/s3"

  project     = var.project
  environment = var.environment

  versioning_enabled             = false
  block_public_access            = true
  enable_replication             = true
  replication_destination_region = "ap-southeast-1"

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# ECR (Container Registry - Primary Region)
# -----------------------------------------------------------------------------
module "ecr" {
  source = "../../modules/ecr"

  project     = var.project
  environment = var.environment

  image_tag_mutability = "MUTABLE"
  scan_on_push         = true
  max_image_count      = 50

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# ALB (Primary Region Only)
# -----------------------------------------------------------------------------
module "alb" {
  source = "../../modules/alb"

  project     = var.project
  environment = var.environment

  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.public_subnet_ids
  internal        = var.alb_internal
  certificate_arn = var.certificate_arn

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# SECONDARY REGION (ap-southeast-1) Resources
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# EKS (Secondary Region - Disaster Recovery)
# -----------------------------------------------------------------------------
module "eks_secondary" {
  source = "../../modules/eks"

  providers = {
    aws = aws.secondary
  }

  project     = var.project
  environment = "${var.environment}-secondary"

  cluster_version        = var.cluster_version
  vpc_id                 = module.vpc_secondary.vpc_id
  private_subnet_ids     = module.vpc_secondary.private_subnet_ids
  public_subnet_ids      = module.vpc_secondary.public_subnet_ids
  node_groups            = var.eks_node_groups
  endpoint_public_access = true
  public_access_cidrs    = ["0.0.0.0/0"]

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# VPC (Secondary Region)
# -----------------------------------------------------------------------------
module "vpc_secondary" {
  source = "../../modules/vpc"

  providers = {
    aws = aws.secondary
  }

  project     = var.project
  environment = "${var.environment}-secondary"

  vpc_cidr           = "10.1.0.0/16"
  availability_zones = ["ap-southeast-1a", "ap-southeast-1b"]
  enable_nat_gateway = true
  single_nat_gateway = true

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# S3 Replication Target (Secondary Region)
# -----------------------------------------------------------------------------
module "s3_secondary" {
  source = "../../modules/s3"

  providers = {
    aws = aws.secondary
  }

  project     = var.project
  environment = "${var.environment}-secondary"

  versioning_enabled         = false
  block_public_access        = true
  is_replication_destination = true

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# ECR (Secondary Region - Disaster Recovery)
# -----------------------------------------------------------------------------
module "ecr_secondary" {
  source = "../../modules/ecr"

  providers = {
    aws = aws.secondary
  }

  project     = var.project
  environment = "${var.environment}-secondary"

  image_tag_mutability = "MUTABLE"
  scan_on_push         = true
  max_image_count      = 50

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# ALB (Secondary Region - Failover Target)
# Active-passive: receives traffic only when primary fails over
# -----------------------------------------------------------------------------
module "alb_secondary" {
  source = "../../modules/alb"

  providers = {
    aws = aws.secondary
  }

  project     = var.project
  environment = "${var.environment}-secondary"

  vpc_id          = module.vpc_secondary.vpc_id
  subnet_ids      = module.vpc_secondary.public_subnet_ids
  internal        = var.alb_internal
  certificate_arn = var.certificate_arn

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# Route53 DNS (Primary Region - Global Routing)
# Active-passive failover with health checks
# -----------------------------------------------------------------------------
module "route53" {
  source = "../../modules/route53"

  project     = var.project
  environment = var.environment

  domain_name           = var.domain_name
  primary_region        = var.aws_region
  secondary_region      = var.secondary_region
  primary_alb_dns       = module.alb.alb_dns_name
  primary_alb_zone_id   = module.alb.alb_zone_id
  secondary_alb_dns     = module.alb_secondary.alb_dns_name
  secondary_alb_zone_id = module.alb_secondary.alb_zone_id
  enable_failover       = true

  tags = local.common_tags
}
