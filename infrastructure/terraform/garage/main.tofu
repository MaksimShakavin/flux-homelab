terraform {
  # This module creates the "terraform" bucket that holds this state, so a fresh
  # Garage must bootstrap with local state (-backend=false) then `-migrate-state`.
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
    # Forked to add website_access on garage_bucket; unpinned because it runs via
    # a ~/.tofurc dev_override until the upstream PR is released.
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
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "homelab"
  item   = "garage"
}

provider "garage" {
  host   = local.garage_admin_endpoint
  scheme = "https"
  token  = module.secret_garage.fields.admin_token
}

provider "onepassword" {}

# Read the node ID from the admin API rather than hardcode it; it's derived from
# node_key at boot and reported before any layout role is assigned. Single node => [0].
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
