terraform {
  # Comment out backend initially, then migrate state after MinIO setup
  # backend "s3" {
  #   bucket = "terraform"
  #   key    = "synology/state.tfstate"
  #   region = "main"
  #   endpoints = {
  #     s3 = "http://192.168.20.5:9000"
  #   }
  #   skip_credentials_validation = true
  #   skip_metadata_api_check     = true
  #   skip_region_validation      = true
  #   force_path_style            = true
  #   skip_requesting_account_id  = true
  # }

  required_providers {
    synology = {
      source  = "synology-community/synology"
      version = "~> 0.6"
    }
  }
}

module "secret_synology" {
  # Remember to export OP_CONNECT_HOST and OP_CONNECT_TOKEN
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "homelab"
  item   = "synology"
}

provider "synology" {
  host     = "https://nas.exelent.click"
  user     = module.secret_synology.fields.username
  password = module.secret_synology.fields.password
  # 1Password returns the full otpauth:// URI; the provider wants the base32 seed
  otp_secret = regex("[?&]secret=([^&]+)", module.secret_synology.fields["one-time password"])[0]
}
