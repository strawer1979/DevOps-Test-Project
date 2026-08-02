output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_cluster_certificate_authority" {
  value = module.eks.cluster_certificate_authority
}

output "eks_oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "rds_endpoint" {
  value = module.rds.db_endpoint
}

output "rds_db_name" {
  value = module.rds.db_name
}

output "redis_endpoint" {
  value = module.elasticache.cluster_endpoint
}

output "redis_port" {
  value = module.elasticache.cluster_port
}

output "s3_bucket_name" {
  value = module.s3.bucket_name
}

output "ecr_repository_urls" {
  value = module.ecr.repository_urls
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

# Secondary region outputs
output "vpc_secondary_id" {
  value = module.vpc_secondary.vpc_id
}

output "eks_secondary_cluster_name" {
  value = module.eks_secondary.cluster_name
}

output "eks_secondary_cluster_endpoint" {
  value = module.eks_secondary.cluster_endpoint
}

output "s3_secondary_bucket_name" {
  value = module.s3_secondary.bucket_name
}

output "ecr_secondary_repository_urls" {
  value = module.ecr_secondary.repository_urls
}

output "secondary_alb_dns" {
  value = module.alb_secondary.alb_dns_name
}

output "route53_zone_id" {
  value = module.route53.zone_id
}

output "domain_name" {
  value = module.route53.domain_name
}
