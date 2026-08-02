terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.40" }
  }
}

variable "project" { type = string }
variable "environment" { type = string }
variable "repository_names" {
  description = "List of ECR repository names (e.g., frontend, api, worker)"
  type        = list(string)
  default     = ["frontend", "api", "worker"]
}
variable "image_tag_mutability" {
  type    = string
  default = "IMMUTABLE"
}
variable "scan_on_push" {
  type    = bool
  default = true
}
variable "max_image_count" {
  description = "Max number of images to keep per repo before cleanup"
  type        = number
  default     = 30
}
variable "tags" {
  type    = map(string)
  default = {}
}

resource "aws_ecr_repository" "this" {
  for_each = toset(var.repository_names)

  name                 = "${var.project}/${each.value}"
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(var.tags, {
    Name        = "${var.project}/${each.value}"
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

# Lifecycle policy to limit image count
resource "aws_ecr_lifecycle_policy" "this" {
  for_each = toset(var.repository_names)

  repository = aws_ecr_repository.this[each.value].name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last ${var.max_image_count} images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = var.max_image_count
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# Repository policy enforcing SSL
resource "aws_ecr_repository_policy" "ssl_only" {
  for_each = toset(var.repository_names)

  repository = aws_ecr_repository.this[each.value].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "EnforceSSL"
      Effect    = "Deny"
      Principal = "*"
      Action    = "ecr:*"
      Condition = {
        Bool = {
          "aws:SecureTransport" = "false"
        }
      }
    }]
  })
}

output "repository_urls" {
  description = "Map of repository names to their URLs"
  value       = { for name, repo in aws_ecr_repository.this : name => repo.repository_url }
}

output "registry_id" {
  value = aws_ecr_repository.this[keys(aws_ecr_repository.this)[0]].registry_id
}
