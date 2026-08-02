project                 = "shopsimple"
environment             = "prod"
region                  = "cn-hangzhou"
secondary_region        = "ap-southeast-1"
cost_center             = "engineering"
vpc_cidr                = "172.16.0.0/12"
availability_zones      = ["cn-hangzhou-h", "cn-hangzhou-i", "cn-hangzhou-j"]
kubernetes_version      = "1.28.3-aliyun.1"
rds_instance_type       = "rds.pg.l1.large"
rds_high_availability   = true
rds_deletion_protection = true
redis_instance_class    = "redis.master.large.default"
redis_node_type         = "double"
enable_nat_gateway      = true
single_nat_gateway      = false
slb_internal            = false
enable_multi_region     = true
domain_name             = "shopsimple.example.com"

ack_node_pools = {
  general = {
    instance_types       = ["ecs.g6.2xlarge"]
    desired_size         = 5
    min_size             = 3
    max_size             = 10
    system_disk_category = "cloud_essd"
    system_disk_size     = 120
    instance_charge_type = "PostPaid"
  }
}
