variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where SLB will be deployed"
  type        = string
}

variable "vswitch_id" {
  description = "VSwitch ID for SLB deployment (required for internal SLB)"
  type        = string
  default     = ""
}

variable "certificate_id" {
  description = "SSL certificate ID for HTTPS listener"
  type        = string
  default     = ""
}

variable "internal" {
  description = "Create internal SLB (private IP)"
  type        = bool
  default     = false
}

variable "target_groups" {
  description = "Map of target groups with port, protocol, path, health_check_path"
  type = map(object({
    port              = number
    protocol          = string
    path              = string
    health_check_path = string
  }))
  default = {
    frontend = {
      port              = 80
      protocol          = "HTTP"
      path              = "/"
      health_check_path = "/health"
    }
    api = {
      port              = 4000
      protocol          = "HTTP"
      path              = "/api"
      health_check_path = "/health"
    }
  }
}

variable "spec" {
  description = "SLB specification"
  type        = string
  default     = "slb.s1.small"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
