variable "project" {
  type    = string
  default = "shopsimple"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "region" {
  description = "Primary Alicloud region"
  type        = string
  default     = "cn-hangzhou"
}

variable "secondary_region" {
  description = "Secondary region for multi-region deployments"
  type        = string
  default     = ""
}

variable "cost_center" {
  type    = string
  default = "engineering"
}

variable "vpc_cidr" {
  type    = string
  default = "172.16.0.0/12"
}

variable "availability_zones" {
  type    = list(string)
  default = ["cn-hangzhou-h", "cn-hangzhou-i"]
}

variable "kubernetes_version" {
  type    = string
  default = "1.28.3-aliyun.1"
}

variable "ack_node_pools" {
  description = "ACK managed node pool definitions"
  type = map(object({
    instance_types       = list(string)
    desired_size         = number
    min_size             = number
    max_size             = number
    system_disk_category = string
    system_disk_size     = number
    instance_charge_type = string
    labels               = optional(map(string), {})
  }))
  default = {
    general = {
      instance_types       = ["ecs.g6.large"]
      desired_size         = 2
      min_size             = 1
      max_size             = 4
      system_disk_category = "cloud_essd"
      system_disk_size     = 120
      instance_charge_type = "PostPaid"
    }
  }
}

variable "rds_instance_type" {
  type    = string
  default = "rds.pg.s1.small"
}

variable "rds_high_availability" {
  type    = bool
  default = false
}

variable "rds_deletion_protection" {
  type    = bool
  default = false
}

variable "redis_instance_class" {
  type    = string
  default = "redis.master.small.default"
}

variable "redis_node_type" {
  description = "single (standalone) or double (HA)"
  type        = string
  default     = "single"
}

variable "enable_nat_gateway" {
  type    = bool
  default = true
}

variable "single_nat_gateway" {
  type    = bool
  default = true
}

variable "slb_internal" {
  type    = bool
  default = false
}

variable "certificate_id" {
  description = "SSL certificate ID for HTTPS listener"
  type        = string
  default     = ""
}

variable "enable_multi_region" {
  description = "Whether to deploy secondary region resources"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Root domain name for DNS routing"
  type        = string
  default     = ""
}
