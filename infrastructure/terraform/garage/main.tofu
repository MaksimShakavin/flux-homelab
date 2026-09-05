terraform {
  # Chicken-and-egg: this module CREATES the "terraform" bucket that stores this
  # very state. On a fresh Garage, bootstrap with local state and skip the
  # backend, then migrate once the bucket exists:
  #   tofu init -backend=false && tofu apply   # creates bucket + keys
  #   tofu init -migrate-state                 # moves state into Garage
  # Backend creds come from AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY (the
  # `terraform` bucket key, published to the garage-buckets 1Password item).
  backend "s3" {
    bucket = "terraform"
    key    = "garage/state.tfstate"
    region = "garage"
    endpoints = {
      s3 = "https://garage-s3.exelent.click"
    }
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    force_path_style            = true
    skip_requesting_account_id  = true
  }

  required_providers {
    # Forked to add website_access on garage_bucket; use dev_overrides in
    # ~/.tofurc pointing at the locally built binary until the upstream PR
    # is merged and released, then pin a version here.
    garage = {
      source = "arsolitt/garagehq"
    }
    http = {
      source = "hashicorp/http"
    }
    onepassword = {
      source = "1Password/onepassword"
    }
  }
}

locals {
  garage_admin_endpoint = "garage-admin.exelent.click"
}

module "secret_garage" {
  # Remember to export OP_CONNECT_HOST and OP_CONNECT_TOKEN
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "homelab"
  item   = "garage"
}

provider "garage" {
  host   = local.garage_admin_endpoint
  scheme = "https"
  token  = module.secret_garage.fields.admin_token
}

# Connect credentials are read from OP_CONNECT_HOST / OP_CONNECT_TOKEN in the
# environment (already exported for Tofu runs).
provider "onepassword" {}

# The node ID is derived from node_key at container boot and is reported by the
# admin API before any layout role is assigned, so we read it directly instead of
# capturing it by hand. Single-node cluster => nodes[0].
data "http" "garage_status" {
  url = "https://${local.garage_admin_endpoint}/v2/GetClusterStatus"
  request_headers = {
    Authorization = "Bearer ${module.secret_garage.fields.admin_token}"
  }
}

resource "garage_cluster_layout" "main" {
  roles {
    id       = jsondecode(data.http.garage_status.response_body).nodes[0].id
    zone     = "dc1"
    capacity = "1G"
    tags     = ["default"]
  }
}
