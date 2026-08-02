variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "bucket_name" {
  description = "OSS bucket name (generated if not provided)"
  type        = string
  default     = ""
}

variable "acl" {
  description = "Bucket ACL"
  type        = string
  default     = "private"
}

variable "versioning" {
  description = "Versioning status"
  type        = string
  default     = "Enabled"
}

variable "sse_algorithm" {
  description = "Server-side encryption algorithm"
  type        = string
  default     = "KMS"
}

variable "lifecycle_rules" {
  description = "Lifecycle rules for bucket"
  type = list(object({
    name       = string
    prefix     = string
    enabled    = bool
    expiration = number # days
  }))
  default = []
}

variable "cors_rules" {
  description = "CORS rules for bucket"
  type = list(object({
    allowed_origins = list(string)
    allowed_methods = list(string)
    allowed_headers = list(string)
    max_age_seconds = number
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
