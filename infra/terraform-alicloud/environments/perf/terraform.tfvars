project                 = "shopsimple"
environment             = "perf"
region                  = "cn-hangzhou"
secondary_region        = "ap-southeast-1"
cost_center             = "engineering"
vpc_cidr                = "172.16.0.0/12"
availability_zones      = ["cn-hangzhou-h", "cn-hangzhou-i", "cn-hangzhou-j"]
kubernetes_version      = "1.28.3-aliyun.1"
rds_instance_type       = "rds.pg.m1.medium"
rds_high_availability   = false
rds_deletion_protection = false
redis_instance_class    = "redis.master.stand.default"
redis_node_type         = "double"
enable_nat_gateway      = true
single_nat_gateway      = true
slb_internal            = false
enable_multi_region     = true
domain_name             = "shopsimple.example.com"

ack_node_pools = {
  general = {
    instance_types       = ["ecs.g6.xlarge"]
    desired_size         = 3
    min_size             = 2
    max_size             = 6
    system_disk_category = "cloud_essd"
    system_disk_size     = 120
    instance_charge_type = "PostPaid"
  }
}
