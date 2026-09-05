terraform {
  backend "s3" {
    bucket = "terraform"
    key    = "authentik/state.tfstate"
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
    authentik = {
      source  = "goauthentik/authentik"
      version = "2026.5.1"
    }
  }
}

module "secret_authentik" {
  # Remember to export OP_CONNECT_HOST and OP_CONNECT_TOKEN
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "homelab"
  item   = "authentik"
}

module "secret_minio" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "homelab"
  item   = "minio"
}

module "secret_portainer" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "homelab"
  item   = "portainer"
}

module "secret_grafana" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "homelab"
  item   = "grafana"
}

module "secret_proxmox" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "homelab"
  item   = "proxmox"
}

module "secret_paperless" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "homelab"
  item   = "paperless"
}

module "secret_audiobookshelf" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "homelab"
  item   = "audiobookshelf"
}

module "secret_lubelogger" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "homelab"
  item   = "lubelogger"
}

module "secret_immich" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "homelab"
  item   = "immich"
}

module "secret_mealie" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "homelab"
  item   = "mealie"
}

module "secret_komga" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "homelab"
  item   = "komga"
}

module "secret_securo" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "homelab"
  item   = "securo"
}

provider "authentik" {
  url   = "https://sso.exelent.click"
  token = module.secret_authentik.fields["AUTHENTIK_TOKEN"]
}
