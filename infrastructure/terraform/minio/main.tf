terraform {
  required_providers {
    minio = {
      source  = "aminueza/minio"
      version = "3.2.2"
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
