terraform {
  required_version = ">= 1.5.0"

  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "~> 1.230"
    }
  }

  backend "oss" {
    bucket              = "shopsimple-terraform-state-alicloud"
    prefix              = "prod"
    region              = "cn-hangzhou"
    tablestore_endpoint = "https://shopsimple-tf-locks.cn-hangzhou.ots.aliyuncs.com"
    tablestore_table    = "terraform-locks"
  }
}

provider "alicloud" {
  region = var.region
}

provider "alicloud" {
  alias  = "secondary"
  region = var.secondary_region
}
