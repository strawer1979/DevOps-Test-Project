variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "cluster_name" {
  description = "Name of the ACK cluster"
  type        = string
  default     = ""
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "1.28.3-aliyun.1"
}

variable "vpc_id" {
  description = "VPC ID for the cluster"
  type        = string
}

variable "private_vswitch_ids" {
  description = "Private vswitch IDs for the cluster"
  type        = list(string)
}

variable "public_vswitch_ids" {
  description = "Public vswitch IDs for the cluster"
  type        = list(string)
}

variable "node_pools" {
  description = "Node pool configurations"
  type = map(object({
    instance_types       = list(string)
    desired_size         = number
    min_size             = number
    max_size             = number
    system_disk_category = string
    system_disk_size     = number
    instance_charge_type = string
  }))
  default = {
    general = {
      instance_types       = ["ecs.g6.xlarge"]
      desired_size         = 2
      min_size             = 1
      max_size             = 4
      system_disk_category = "cloud_essd"
      system_disk_size     = 120
      instance_charge_type = "PostPaid"
    }
  }
}

variable "endpoint_public_access" {
  description = "Enable public endpoint access to the cluster API server"
  type        = bool
  default     = false
}

variable "api_server_whitelist" {
  description = "CIDR blocks to whitelist for API server public access"
  type        = list(string)
  default     = []
}

variable "new_nat_gateway" {
  description = "Whether to create a new NAT gateway for the cluster"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
