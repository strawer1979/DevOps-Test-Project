locals {
  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
    },
    var.tags
  )

  # Generate bucket name if not provided
  bucket_name = var.bucket_name != "" ? var.bucket_name : "${var.project}-${var.environment}-storage"
}

# OSS Bucket
resource "alicloud_oss_bucket" "this" {
  bucket = local.bucket_name

  acl = var.acl

  # Versioning configuration
  versioning {
    status = var.versioning
  }

  # Server-side encryption
  server_side_encryption_rule {
    sse_algorithm = var.sse_algorithm
  }

  # Lifecycle rules
  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules
    content {
      name    = lifecycle_rule.value.name
      prefix  = lifecycle_rule.value.prefix
      enabled = lifecycle_rule.value.enabled

      expiration {
        days = lifecycle_rule.value.expiration
      }
    }
  }

  # CORS rules
  dynamic "cors_rule" {
    for_each = var.cors_rules
    content {
      allowed_origins = cors_rule.value.allowed_origins
      allowed_methods = cors_rule.value.allowed_methods
      allowed_headers = cors_rule.value.allowed_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }

  # Tags
  tags = local.common_tags
}

# Bucket Policy for HTTPS-only
resource "alicloud_oss_bucket_policy" "https_only" {
  bucket = alicloud_oss_bucket.this.bucket

  policy = jsonencode({
    "Statement" = [
      {
        "Action" = [
          "oss:*"
        ],
        "Effect"    = "Deny",
        "Principal" = "*",
        "Resource" = [
          "acs:oss:*:*:${local.bucket_name}",
          "acs:oss:*:*:${local.bucket_name}/*"
        ],
        "Condition" = {
          "Bool" = {
            "acs:SecureTransport" = "false"
          }
        }
      }
    ],
    "Version" = "1"
  })
}
