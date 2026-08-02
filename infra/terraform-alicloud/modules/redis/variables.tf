variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where Redis will be deployed"
  type        = string
}

variable "vswitch_id" {
  description = "VSwitch ID for Redis deployment"
  type        = string
}

variable "allowed_security_group_ids" {
  description = "List of security group IDs to allow access to Redis"
  type        = list(string)
  default     = []
}

variable "instance_class" {
  description = "Redis instance class"
  type        = string
  default     = "redis.master.small.default"
}

variable "instance_type" {
  description = "Redis instance type"
  type        = string
  default     = "Redis"
}

variable "engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.0"
}

variable "node_type" {
  description = "Node type (double for HA)"
  type        = string
  default     = "double"
}

variable "shard_count" {
  description = "Number of shards"
  type        = number
  default     = 1
}

variable "password" {
  description = "Redis password (optional, will generate if not provided)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
