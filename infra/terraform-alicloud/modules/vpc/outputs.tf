output "vpc_id" {
  description = "ID of the VPC"
  value       = alicloud_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = alicloud_vpc.this.cidr_block
}

output "public_vswitch_ids" {
  description = "IDs of public vswitches"
  value       = alicloud_vswitch.public[*].id
}

output "private_vswitch_ids" {
  description = "IDs of private vswitches"
  value       = alicloud_vswitch.private[*].id
}

output "database_vswitch_ids" {
  description = "IDs of database vswitches"
  value       = alicloud_vswitch.database[*].id
}

output "nat_gateway_ips" {
  description = "Public IP addresses of NAT Gateways"
  value       = var.enable_nat_gateway ? alicloud_eip_address.this[*].ip_address : []
}

output "default_security_group_id" {
  description = "ID of the default security group"
  value       = alicloud_security_group.default.id
}
