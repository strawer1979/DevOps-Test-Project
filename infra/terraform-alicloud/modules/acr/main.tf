locals {
  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
    },
    var.tags
  )

  # Determine if tag immutability should be enabled based on environment
  # Production should have immutable tags to prevent overwriting
  tag_immutability = var.environment == "prod" ? true : false

  # Generate repo URLs
  repo_urls = { for repo in var.repo_names : repo => "registry.aliyuncs.com/${var.namespace}/${repo}" }
}

# ACR Enterprise Edition Namespace
resource "alicloud_cr_ee_namespace" "this" {
  namespace          = var.namespace
  auto_create        = false
  default_visibility = var.repo_type # PUBLIC or PRIVATE

  tags = local.common_tags
}

# ACR Repositories
resource "alicloud_cr_ee_repo" "this" {
  count = length(var.repo_names)

  repo_name        = var.repo_names[count.index]
  repo_type        = var.repo_type
  namespace        = alicloud_cr_ee_namespace.this.namespace
  summary          = var.summary
  detail           = "Container repository for ${var.repo_names[count.index]}"
  tag_immutability = local.tag_immutability

  # Note: The repo is created within the namespace
  # The provider will handle the relationship
}

# Get registry info for outputs
data "alicloud_cr_ee_instances" "this" {
  name = var.namespace
}
