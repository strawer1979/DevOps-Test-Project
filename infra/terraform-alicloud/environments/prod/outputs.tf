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

# Secondary Region Outputs
output "secondary_vpc_id" {
  value = module.vpc_secondary.vpc_id
}

output "secondary_ack_cluster_id" {
  value = module.ack_secondary.cluster_id
}

output "secondary_oss_bucket_name" {
  value = module.oss_secondary.bucket_name
}

output "secondary_acr_repo_urls" {
  value = module.acr_secondary.repo_urls
}

# Secondary SLB
output "secondary_slb_address" {
  value = module.slb_secondary.slb_address
}

# DNS Outputs
output "dns_domain_name" {
  value = module.dns.domain_name
}

output "primary_regional_fqdn" {
  value = module.dns.primary_regional_fqdn
}

output "secondary_regional_fqdn" {
  value = module.dns.secondary_regional_fqdn
}
