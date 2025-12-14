terraform {
  # comment out backend in case you are running it first time on a fresh minio. After you are done, run
  # terraform init -migrate-state to migrate state to newly create minio bucket
  backend "s3" {
    bucket                      = "terraform"
    key                         = "minio/state.tfstate"
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
    minio = {
      source  = "aminueza/minio"
      version = "3.12.0"
    }
  }
}

module "secret_minio" {
  # Remember to export OP_CONNECT_HOST and OP_CONNECT_TOKEN
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "homelab"
  item   = "minio"
}

provider "minio" {
  minio_server   = "192.168.20.5:9000"
  minio_user     = module.secret_minio.fields.MINIO_ROOT_USER
  minio_password = module.secret_minio.fields.MINIO_ROOT_PASSWORD
  minio_ssl      = false
}
