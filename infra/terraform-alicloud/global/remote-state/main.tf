terraform {
  required_version = ">= 1.5.0"

  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "~> 1.230"
    }
  }
}

provider "alicloud" {
  region = var.region
}

# -----------------------------------------------------------------------------
# OSS bucket for Terraform remote state
# -----------------------------------------------------------------------------
resource "alicloud_oss_bucket" "terraform_state" {
  bucket = "shopsimple-terraform-state-alicloud"

  versioning {
    status = "Enabled"
  }

  server_side_encryption_rule {
    sse_algorithm = "KMS"
  }

  tags = {
    Name      = "shopsimple-terraform-state-alicloud"
    ManagedBy = "terraform"
  }
}

# -----------------------------------------------------------------------------
# OTS (Table Store) table for state locking
# Note: Alicloud uses OTS (similar to DynamoDB) for Terraform state locking
# -----------------------------------------------------------------------------
resource "alicloud_ots_instance" "terraform_locks" {
  name        = "shopsimple-tf-locks"
  description = "Terraform state locking table"
}

resource "alicloud_ots_table" "terraform_locks" {
  instance_name = alicloud_ots_instance.terraform_locks.name
  table_name    = "terraform-locks"

  primary_key {
    name = "LockID"
    type = "String"
  }

  time_to_live = -1
  max_version  = 1
}

output "state_bucket_name" {
  value = alicloud_oss_bucket.terraform_state.bucket
}

output "lock_table_name" {
  value = alicloud_ots_table.terraform_locks.table_name
}

output "ots_instance_name" {
  value = alicloud_ots_instance.terraform_locks.name
}
