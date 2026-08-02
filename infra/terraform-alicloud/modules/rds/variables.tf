variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where RDS will be deployed"
  type        = string
}

variable "vswitch_ids" {
  description = "List of VSwitch IDs for RDS deployment"
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "List of security group IDs to allow access to RDS"
  type        = list(string)
  default     = []
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "shopsimple"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "shopsimple_admin"
}

variable "instance_type" {
  description = "RDS instance type"
  type        = string
  default     = "rds.pg.s1.small"
}

variable "engine" {
  description = "Database engine"
  type        = string
  default     = "PostgreSQL"
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
  default     = "16.0"
}

variable "storage" {
  description = "Initial storage in GB"
  type        = number
  default     = 20
}

variable "max_storage" {
  description = "Maximum storage in GB"
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "Storage type"
  type        = string
  default     = "cloud_essd"
}

variable "high_availability" {
  description = "Enable high availability mode"
  type        = bool
  default     = false
}

variable "backup_time" {
  description = "Backup time window in UTC"
  type        = string
  default     = "02:00Z-03:00Z"
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
