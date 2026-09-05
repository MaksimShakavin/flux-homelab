terraform {
  # State lives in the Garage `terraform` bucket, reached at garage-s3.exelent.click
  # — a CNAME this very module creates (see dns.tofu). On a fresh setup that name
  # doesn't resolve yet, so bootstrap with local state and migrate once Garage +
  # DNS exist:
  #   tofu init -backend=false && tofu apply   # creates garage-* DNS records
  #   tofu init -migrate-state                 # after garage bucket + DNS exist
  # Backend creds come from AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY (the
  # `terraform` bucket key, published to the garage-buckets 1Password item).
  backend "s3" {
    bucket = "terraform"
    key    = "unifi/state.tfstate"
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
    unifi = {
      source  = "ubiquiti-community/unifi"
      version = "0.55.0"
    }
  }
}

module "secret_unifi" {
  # Remember to export OP_CONNECT_HOST and OP_CONNECT_TOKEN
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "homelab"
  item   = "Unifi"
}

module "secret_cloudflare" {
  # Remember to export OP_CONNECT_HOST and OP_CONNECT_TOKEN
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "homelab"
  item   = "cloudflare"
}

provider "unifi" {
  username       = module.secret_unifi.fields.TERRAFORM_USER
  password       = module.secret_unifi.fields.TERRAFORM_PASSWORD
  api_url        = "https://192.168.0.1"
  allow_insecure = true
}
