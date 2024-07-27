module "cnpg_bucket" {
  source           = "./minio-bucket"
  bucket_name      = "cloudnative_pg"
  owner_access_key = module.secret_minio.fields.MINIO_CNPG_ACCESS_KEY
  owner_secret_key = module.secret_minio.fields.MINIO_CNPG_SECRET_KEY
  is_public        = false
}

output "cnpg_bucket_outputs" {
  value     = module.cnpg_bucket
  sensitive = true
}
