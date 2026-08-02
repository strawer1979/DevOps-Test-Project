# -----------------------------------------------------------------------------
# Dev Environment — ShopSimple
# Single region (us-east-1), minimal resources
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
# VPC
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
# EKS
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
# RDS (PostgreSQL)
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
# ElastiCache (Redis)
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
# S3 (Product Images)
# -----------------------------------------------------------------------------
module "s3" {
  source = "../../modules/s3"

  project     = var.project
  environment = var.environment

  versioning_enabled  = false
  block_public_access = true

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# ECR (Container Registry)
# -----------------------------------------------------------------------------
module "ecr" {
  source = "../../modules/ecr"

  project     = var.project
  environment = var.environment

  image_tag_mutability = "MUTABLE"
  scan_on_push         = true
  max_image_count      = 20

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# ALB
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
