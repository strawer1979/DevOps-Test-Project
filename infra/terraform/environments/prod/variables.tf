variable "project" {
  type    = string
  default = "shopsimple"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "cost_center" {
  type    = string
  default = "engineering"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "cluster_version" {
  type    = string
  default = "1.29"
}

variable "eks_node_groups" {
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
      instance_types = ["t3.large"]
      desired_size   = 5
      min_size       = 3
      max_size       = 10
      disk_size      = 100
      capacity_type  = "ON_DEMAND"
    }
  }
}

variable "rds_instance_class" {
  type    = string
  default = "db.t4g.large"
}

variable "rds_multi_az" {
  type    = bool
  default = true
}

variable "rds_deletion_protection" {
  type    = bool
  default = true
}

variable "redis_node_type" {
  type    = string
  default = "cache.t4g.medium"
}

variable "redis_num_cache_clusters" {
  type    = number
  default = 3
}

variable "enable_nat_gateway" {
  type    = bool
  default = true
}

variable "single_nat_gateway" {
  type    = bool
  default = false
}

variable "alb_internal" {
  type    = bool
  default = false
}

variable "certificate_arn" {
  type    = string
  default = ""
}

variable "secondary_region" {
  description = "Secondary AWS region for multi-region deployment"
  type        = string
  default     = "ap-southeast-1"
}

variable "domain_name" {
  description = "Root domain name for Route53 DNS"
  type        = string
  default     = "shopsimple.example.com"
}

variable "enable_multi_region" {
  description = "Enable multi-region deployment"
  type        = bool
  default     = true
}
