output "db_connection_string" {
  description = "Database connection string"
  value       = alicloud_db_connection.this.connection_string
}

output "db_port" {
  description = "Database port"
  value       = alicloud_db_connection.this.port
}

output "db_instance_id" {
  description = "Database instance ID"
  value       = alicloud_db_instance.this.id
}

output "db_name" {
  description = "Database name"
  value       = var.db_name
}

output "db_username" {
  description = "Database username"
  value       = var.db_username
}

output "db_password" {
  description = "Database password"
  value       = random_password.db_password.result
  sensitive   = true
}

output "security_group_id" {
  description = "Security group ID for RDS"
  value       = alicloud_security_group.rds.id
}
