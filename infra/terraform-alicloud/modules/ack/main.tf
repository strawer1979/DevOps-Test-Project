locals {
  cluster_name = var.cluster_name != "" ? var.cluster_name : "${var.project}-${var.environment}-ack"

  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
    },
    var.tags
  )

  # Determine cluster spec based on environment
  cluster_spec = var.environment == "prod" ? "ack.pro.small" : "ack.pro.small"

  # Addons configuration
  addons = [
    {
      name    = "terway-eniip"
      config  = ""
      enabled = true
    },
    {
      name    = "csi-plugin"
      config  = ""
      enabled = true
    },
    {
      name    = "csi-provisioner"
      config  = ""
      enabled = true
    },
    {
      name = "nginx-ingress-controller"
      config = jsonencode({
        "IngressSlbSpec" = "slb.s1.small"
        "IngressBackend" = "nginx-ingress-controller"
        "Namespace"      = "ingress-basic"
        "SlbNetworkType" = "internet"
      })
      enabled = true
    }
  ]

  # Deletion protection based on environment
  deletion_protection = var.environment == "prod" ? true : false
}

# Managed Kubernetes Cluster
resource "alicloud_cs_managed_kubernetes" "this" {
  name                 = local.cluster_name
  cluster_spec         = local.cluster_spec
  kubernetes_version   = var.kubernetes_version
  vpc_id               = var.vpc_id
  pod_vswitch_ids      = var.private_vswitch_ids
  new_nat_gateway      = var.new_nat_gateway
  service_cidr         = "192.168.0.0/16"
  slb_internet_enabled = var.endpoint_public_access

  dynamic "api_server_white_list" {
    for_each = var.endpoint_public_access && length(var.api_server_whitelist) > 0 ? var.api_server_whitelist : []
    content {
      cidr_block = api_server_white_list.value
    }
  }

  dynamic "addons" {
    for_each = local.addons
    content {
      name    = addons.value.name
      config  = addons.value.config
      enabled = addons.value.enabled
    }
  }

  # Enable RRSA (RAM Role for Service Accounts)
  rbac_enabled = true
  rrsa_enabled = true

  # Deletion protection
  deletion_protection = local.deletion_protection

  # Tags
  tags = local.common_tags

  timeouts {
    create = "90m"
    update = "60m"
    delete = "30m"
  }
}

# Node Pools
resource "alicloud_cs_node_pool" "this" {
  for_each = var.node_pools

  cluster_id           = alicloud_cs_managed_kubernetes.this.id
  node_pool_name       = "${local.cluster_name}-${each.key}"
  vswitch_ids          = var.private_vswitch_ids
  instance_types       = each.value.instance_types
  desired_size         = each.value.desired_size
  min_size             = each.value.min_size
  max_size             = each.value.max_size
  system_disk_category = each.value.system_disk_category
  system_disk_size     = each.value.system_disk_size
  instance_charge_type = each.value.instance_charge_type

  scaling_config {
    enable       = true
    min_size     = each.value.min_size
    max_size     = each.value.max_size
    desired_size = each.value.desired_size
  }

  labels = {
    "node-pool" = each.key
  }

  tags = merge(local.common_tags, {
    "NodePool" = each.key
  })

  timeouts {
    create = "60m"
    update = "60m"
    delete = "30m"
  }
}

# RAM Role for ACK Workers
resource "alicloud_ram_role" "worker" {
  name        = "${local.cluster_name}-worker-role"
  description = "RAM role for ACK worker nodes"
  force       = true
}

# RAM Policy for Worker Nodes (access to OSS, ACR, etc.)
resource "alicloud_ram_policy" "worker" {
  name        = "${local.cluster_name}-worker-policy"
  description = "RAM policy for ACK worker nodes to access OSS, ACR, and other services"
  force       = true

  document = jsonencode({
    "Statement" = [
      {
        "Action" = [
          "oss:GetObject",
          "oss:PutObject",
          "oss:DeleteObject",
          "oss:ListBucket",
          "oss:GetBucketInfo"
        ],
        "Effect" = "Allow",
        "Resource" = [
          "acs:oss:*:*:*"
        ]
      },
      {
        "Action" = [
          "cr:GetImage",
          "cr:ListImage",
          "cr:PullImage"
        ],
        "Effect" = "Allow",
        "Resource" = [
          "acs:cr:*:*:*"
        ]
      }
    ],
    "Version" = "1"
  })
}

# Attach Policy to Role
resource "alicloud_ram_role_policy_attachment" "worker" {
  policy_name = alicloud_ram_policy.worker.name
  policy_type = "Custom"
  role_name   = alicloud_ram_role.worker.name
}
