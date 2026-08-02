project                 = "shopsimple"
environment             = "test"
region                  = "cn-hangzhou"
cost_center             = "engineering"
vpc_cidr                = "172.16.0.0/12"
availability_zones      = ["cn-hangzhou-h", "cn-hangzhou-i"]
kubernetes_version      = "1.28.3-aliyun.1"
rds_instance_type       = "rds.pg.s1.small"
rds_high_availability   = false
rds_deletion_protection = false
redis_instance_class    = "redis.master.small.default"
redis_node_type         = "single"
enable_nat_gateway      = true
single_nat_gateway      = true
slb_internal            = false
enable_multi_region     = false
domain_name             = ""

ack_node_pools = {
  general = {
    instance_types       = ["ecs.g6.large"]
    desired_size         = 2
    min_size             = 1
    max_size             = 4
    system_disk_category = "cloud_essd"
    system_disk_size     = 120
    instance_charge_type = "PostPaid"
  }
}
