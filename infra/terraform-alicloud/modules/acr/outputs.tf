output "namespace_name" {
  description = "ACR namespace name"
  value       = alicloud_cr_ee_namespace.this.namespace
}

output "repo_urls" {
  description = "Map of repository names to URLs"
  value       = local.repo_urls
}

output "registry_id" {
  description = "ACR registry ID"
  value       = length(data.alicloud_cr_ee_instances.this.instances) > 0 ? data.alicloud_cr_ee_instances.this.instances[0].id : ""
}
