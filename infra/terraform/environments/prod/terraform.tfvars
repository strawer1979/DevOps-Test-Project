project                  = "shopsimple"
environment              = "prod"
aws_region               = "us-east-1"
secondary_region         = "ap-southeast-1"
domain_name              = "shopsimple.example.com"
enable_multi_region      = true
cost_center              = "engineering"
vpc_cidr                 = "10.0.0.0/16"
availability_zones       = ["us-east-1a", "us-east-1b", "us-east-1c"]
cluster_version          = "1.29"
rds_instance_class       = "db.t4g.large"
rds_multi_az             = true
rds_deletion_protection  = true
redis_node_type          = "cache.t4g.medium"
redis_num_cache_clusters = 3
enable_nat_gateway       = true
single_nat_gateway       = false
alb_internal             = false

eks_node_groups = {
  general = {
    instance_types = ["t3.large"]
    desired_size   = 5
    min_size       = 3
    max_size       = 10
    disk_size      = 100
    capacity_type  = "ON_DEMAND"
  }
}
