output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_vswitch_ids" {
  value = module.vpc.private_vswitch_ids
}

output "public_vswitch_ids" {
  value = module.vpc.public_vswitch_ids
}

output "ack_cluster_id" {
  value = module.ack.cluster_id
}

output "ack_cluster_name" {
  value = module.ack.cluster_name
}

output "ack_cluster_endpoint" {
  value     = module.ack.cluster_endpoint
  sensitive = true
}

output "rds_connection_string" {
  value = module.rds.db_connection_string
}

output "rds_db_name" {
  value = module.rds.db_name
}

output "redis_connection_domain" {
  value = module.redis.connection_domain
}

output "redis_port" {
  value = module.redis.port
}

output "oss_bucket_name" {
  value = module.oss.bucket_name
}

output "oss_bucket_domain" {
  value = module.oss.bucket_domain
}

output "acr_repo_urls" {
  value = module.acr.repo_urls
}

output "slb_address" {
  value = module.slb.slb_address
}

output "dns_domain_name" {
  value = var.domain_name
}

# Conditional Secondary Region Outputs
output "secondary_vpc_id" {
  value = var.enable_multi_region ? module.vpc_secondary[0].vpc_id : null
  #  value = module.vpc_secondary[0].vpc_id
}

output "secondary_ack_cluster_id" {
  value = var.enable_multi_region ? module.ack_secondary[0].cluster_id : null
}

output "secondary_oss_bucket_name" {
  value = var.enable_multi_region ? module.oss_secondary[0].bucket_name : null
}

output "secondary_acr_repo_urls" {
  value = var.enable_multi_region ? module.acr_secondary[0].repo_urls : null
}

output "secondary_slb_address" {
  value = var.enable_multi_region ? module.slb_secondary[0].slb_address : null
}
