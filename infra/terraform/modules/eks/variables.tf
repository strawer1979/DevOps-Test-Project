variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "cluster_name" {
  description = "Override cluster name (defaults to project-environment)"
  type        = string
  default     = ""
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "node_groups" {
  description = "EKS managed node group definitions"
  type = map(object({
    instance_types = list(string)
    desired_size   = number
    min_size       = number
    max_size       = number
    disk_size      = number
    capacity_type  = string
    labels         = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
  }))
  default = {
    general = {
      instance_types = ["t3.small"]
      desired_size   = 2
      min_size       = 1
      max_size       = 4
      disk_size      = 50
      capacity_type  = "ON_DEMAND"
    }
  }
}

variable "endpoint_private_access" {
  type    = bool
  default = true
}

variable "endpoint_public_access" {
  type    = bool
  default = false
}

variable "public_access_cidrs" {
  type    = list(string)
  default = []
}

variable "enable_cluster_creator_admin_permissions" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
