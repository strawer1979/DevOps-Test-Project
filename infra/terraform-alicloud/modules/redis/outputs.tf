output "instance_id" {
  description = "Redis instance ID"
  value       = alicloud_kvstore_instance.this.id
}

output "connection_domain" {
  description = "Redis connection domain"
  value       = alicloud_kvstore_connection.this.connection_string
}

output "port" {
  description = "Redis port"
  value       = alicloud_kvstore_connection.this.port
}

output "password" {
  description = "Redis password"
  value       = local.redis_password
  sensitive   = true
}

output "security_group_id" {
  description = "Security group ID for Redis"
  value       = alicloud_security_group.redis.id
}
