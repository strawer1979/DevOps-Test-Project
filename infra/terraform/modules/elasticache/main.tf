terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 5.40" }
    random = { source = "hashicorp/random", version = "~> 3.6" }
  }
}

variable "project" { type = string }
variable "environment" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "allowed_security_group_ids" {
  type    = list(string)
  default = []
}

variable "node_type" {
  type    = string
  default = "cache.t4g.micro"
}
variable "num_cache_clusters" {
  type    = number
  default = 1
}
variable "engine_version" {
  type    = string
  default = "7.1"
}
variable "automatic_failover_enabled" {
  type    = bool
  default = false
}
variable "tags" {
  type    = map(string)
  default = {}
}

resource "random_password" "auth_token" {
  length  = 32
  special = false
}

resource "aws_security_group" "redis" {
  name_prefix = "${var.project}-${var.environment}-redis-"
  vpc_id      = var.vpc_id
  description = "Security group for ElastiCache Redis"

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
    description     = "Redis access from allowed security groups"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name        = "${var.project}-${var.environment}-redis-sg"
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  lifecycle { create_before_destroy = true }
}

resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.project}-${var.environment}-redis-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, { ManagedBy = "terraform" })
}

resource "aws_elasticache_parameter_group" "this" {
  name   = "${var.project}-${var.environment}-redis-params"
  family = "redis7"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  tags = merge(var.tags, { ManagedBy = "terraform" })
}

resource "aws_elasticache_cluster" "this" {
  cluster_id           = "${var.project}-${var.environment}-redis"
  engine               = "redis"
  engine_version       = var.engine_version
  node_type            = var.node_type
  num_cache_nodes      = var.num_cache_clusters
  parameter_group_name = aws_elasticache_parameter_group.this.name
  subnet_group_name    = aws_elasticache_subnet_group.this.name
  security_group_ids   = [aws_security_group.redis.id]
  port                 = 6379
  apply_immediately    = true

  tags = merge(var.tags, {
    Name        = "${var.project}-${var.environment}-redis"
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

output "cluster_endpoint" {
  value = aws_elasticache_cluster.this.cache_nodes[0].address
}

output "cluster_port" {
  value = aws_elasticache_cluster.this.port
}

output "security_group_id" {
  value = aws_security_group.redis.id
}

output "auth_token" {
  value     = random_password.auth_token.result
  sensitive = true
}
