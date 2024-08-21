module "terraform_bucket" {
  source           = "./minio-bucket"
  bucket_name      = "terraform"
  owner_access_key = module.secret_minio.fields.MINIO_TFSTATE_ACCESS_KEY
  owner_secret_key = module.secret_minio.fields.MINIO_TFSTATE_SECRET_KEY
  is_public        = false
}

output "terraform_bucket_outputs" {
  value     = module.terraform_bucket
  sensitive = true
}
