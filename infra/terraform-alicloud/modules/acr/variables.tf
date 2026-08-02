variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "namespace" {
  description = "ACR namespace"
  type        = string
  default     = "shopsimple"
}

variable "repo_names" {
  description = "List of repository names"
  type        = list(string)
  default     = ["frontend", "api", "worker"]
}

variable "repo_type" {
  description = "Repository type (PUBLIC or PRIVATE)"
  type        = string
  default     = "PUBLIC"
}

variable "summary" {
  description = "Default summary for repositories"
  type        = string
  default     = "Container repository"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
