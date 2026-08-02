output "cluster_id" {
  description = "ID of the ACK cluster"
  value       = alicloud_cs_managed_kubernetes.this.id
}

output "cluster_name" {
  description = "Name of the ACK cluster"
  value       = local.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint of the ACK cluster API server"
  value       = alicloud_cs_managed_kubernetes.this.api_server_endpoint
  sensitive   = true
}

output "kube_config" {
  description = "Kubeconfig for accessing the cluster"
  value       = alicloud_cs_managed_kubernetes.this.kube_config
  sensitive   = true
}

output "worker_ram_role_name" {
  description = "Name of the RAM role for worker nodes"
  value       = alicloud_ram_role.worker.name
}

output "node_pool_ids" {
  description = "IDs of the node pools"
  value       = { for k, v in alicloud_cs_node_pool.this : k => v.id }
}

output "security_group_id" {
  description = "Security group ID associated with the cluster"
  value       = alicloud_cs_managed_kubernetes.this.security_group_id
}
