module "loki_bucket" {
  source           = "./minio-bucket"
  bucket_name      = "cloudnative_pg"
  owner_access_key = module.secret_minio.fields.MINIO_LOKI_ACCESS_KEY
  owner_secret_key = module.secret_minio.fields.MINIO_LOKI_SECRET_KEY
  is_public        = false
}

output "loki_bucket_outputs" {
  value     = module.loki_bucket
  sensitive = true
}
