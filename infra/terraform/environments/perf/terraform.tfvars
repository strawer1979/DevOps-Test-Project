project                  = "shopsimple"
environment              = "perf"
aws_region               = "us-east-1"
secondary_region         = "ap-southeast-1"
domain_name              = "shopsimple.example.com"
enable_multi_region      = true
cost_center              = "engineering"
vpc_cidr                 = "10.0.0.0/16"
availability_zones       = ["us-east-1a", "us-east-1b", "us-east-1c"]
cluster_version          = "1.29"
rds_instance_class       = "db.t4g.medium"
rds_multi_az             = false
rds_deletion_protection  = false
redis_node_type          = "cache.t4g.small"
redis_num_cache_clusters = 2
enable_nat_gateway       = true
single_nat_gateway       = true
alb_internal             = false

eks_node_groups = {
  general = {
    instance_types = ["t3.medium"]
    desired_size   = 3
    min_size       = 2
    max_size       = 6
    disk_size      = 80
    capacity_type  = "ON_DEMAND"
  }
}
