project                  = "shopsimple"
environment              = "test"
aws_region               = "us-east-1"
cost_center              = "engineering"
vpc_cidr                 = "10.0.0.0/16"
availability_zones       = ["us-east-1a", "us-east-1b"]
cluster_version          = "1.29"
rds_instance_class       = "db.t4g.micro"
rds_multi_az             = false
rds_deletion_protection  = false
redis_node_type          = "cache.t4g.micro"
redis_num_cache_clusters = 1
enable_nat_gateway       = true
single_nat_gateway       = true
alb_internal             = false

eks_node_groups = {
  general = {
    instance_types = ["t3.small"]
    desired_size   = 2
    min_size       = 1
    max_size       = 4
    disk_size      = 50
    capacity_type  = "ON_DEMAND"
  }
}
