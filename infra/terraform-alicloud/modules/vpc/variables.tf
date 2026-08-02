variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "172.16.0.0/12"
}

variable "availability_zones" {
  description = "Availability zones for the VPC"
  type        = list(string)
  default     = ["cn-hangzhou-h", "cn-hangzhou-i", "cn-hangzhou-j"]
}

variable "public_vswitch_cidrs" {
  description = "CIDR blocks for public vswitches"
  type        = list(string)
  default     = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
}

variable "private_vswitch_cidrs" {
  description = "CIDR blocks for private vswitches"
  type        = list(string)
  default     = ["172.16.10.0/24", "172.16.20.0/24", "172.16.30.0/24"]
}

variable "database_vswitch_cidrs" {
  description = "CIDR blocks for database vswitches"
  type        = list(string)
  default     = ["172.16.100.0/24", "172.16.110.0/24", "172.16.120.0/24"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnet internet access"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all availability zones"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
