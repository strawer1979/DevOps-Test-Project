output "slb_id" {
  description = "SLB instance ID"
  value       = alicloud_slb_load_balancer.this.id
}

output "slb_address" {
  description = "SLB public IP address"
  value       = var.internal ? "" : alicloud_slb_load_balancer.this.address
}

output "slb_internal_address" {
  description = "SLB internal IP address"
  value       = alicloud_slb_load_balancer.this.address
}

output "server_group_ids" {
  description = "Map of target group names to server group IDs"
  value       = { for i, tg in var.target_groups : keys(var.target_groups)[i] => alicloud_slb_server_group.this[i].id }
}

output "listener_ids" {
  description = "Map of listener ports to listener IDs"
  value = merge(
    { "http" : alicloud_slb_listener.http.id },
    length(alicloud_slb_listener.https) > 0 ? { "https" : alicloud_slb_listener.https[0].id } : {}
  )
}
