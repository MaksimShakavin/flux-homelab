terraform {
#  backend "s3" {
#    bucket                      = "terraform"
#    key                         = "proxmox/state.tfstate"
#    skip_credentials_validation = true
#    skip_metadata_api_check     = true
#    skip_region_validation      = true
#    force_path_style            = true
#  }

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.67.1"
    }
    unifi = {
      source  = "paultyng/unifi"
      version = "0.41.0"
    }
  }
}

module "secret_pve" {
  # Remember to export OP_CONNECT_HOST and OP_CONNECT_TOKEN
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "homelab"
  item   = "Proxmox root"
}

module "secret_unifi" {
  # Remember to export OP_CONNECT_HOST and OP_CONNECT_TOKEN
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "homelab"
  item   = "Unifi"
}

provider "proxmox" {
  endpoint = "https://192.168.0.41:8006/"
  username = "${module.secret_pve.fields.username}@pam"
  password = module.secret_pve.fields.password
  insecure = true
}

provider "unifi" {
  username = module.secret_unifi.fields.username
  password = module.secret_unifi.fields.password
  api_url  = "https://192.168.0.1"
  allow_insecure = true
}
