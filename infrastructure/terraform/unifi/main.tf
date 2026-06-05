terraform {
  # comment out backend in case you are running it first time on a fresh minio. After you are done, run
  # terraform init -migrate-state to migrate state to newly create minio bucket
  # backend "s3" {
  #   bucket                      = "terraform"
  #   key                         = "unifi/state.tfstate"
  #   region                      = "main"
  #   endpoints = {
  #     s3                          = "http://192.168.20.5:9000"
  #   }
  #   skip_credentials_validation = true
  #   skip_metadata_api_check     = true
  #   skip_region_validation      = true
  #   force_path_style            = true
  #   skip_requesting_account_id  = true
  # }

  required_providers {
    unifi = {
      source  = "ubiquiti-community/unifi"
      version = "0.41.25"
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
  username = module.secret_unifi.fields.TERRAFORM_USER
  password = module.secret_unifi.fields.TERRAFORM_PASSWORD
  api_url  = "https://192.168.0.1"
  allow_insecure = true
}
