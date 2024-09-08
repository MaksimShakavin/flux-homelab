terraform {
  backend "s3" {
    bucket                      = "terraform"
    key                         = "authentik/state.tfstate"
    region                      = "main"
    endpoints = {
      s3                          = "http://192.168.20.5:9000"
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
      version = "2024.8.2"
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

module "secret_grafana" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "Homelab"
  item   = "grafana"
}

module "secret_proxmox" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "Homelab"
  item   = "proxmox"
}

module "secret_paperless" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "Homelab"
  item   = "paperless"
}

module "secret_audiobookshelf" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "Homelab"
  item   = "audiobookshelf"
}

module "secret_mealie" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "Homelab"
  item   = "mealie"
}

provider "authentik" {
  url   = "https://sso.exelent.click"
  token = module.secret_authentik.fields["AUTHENTIK_TOKEN"]
}
