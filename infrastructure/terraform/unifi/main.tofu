terraform {
  # The S3 endpoint is a CNAME this module creates (dns.tofu), so a fresh setup
  # must bootstrap with local state (-backend=false) then `tofu init -migrate-state`.
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
      version = "0.60.0"
    }
  }
}

module "secret_unifi" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "homelab"
  item   = "Unifi"
}

module "secret_cloudflare" {
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
