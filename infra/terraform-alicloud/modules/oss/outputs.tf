output "bucket_name" {
  description = "OSS bucket name"
  value       = alicloud_oss_bucket.this.bucket
}

output "bucket_domain" {
  description = "OSS bucket domain"
  value       = alicloud_oss_bucket.this.bucket_domain
}

output "bucket_id" {
  description = "OSS bucket ID"
  value       = alicloud_oss_bucket.this.id
}
