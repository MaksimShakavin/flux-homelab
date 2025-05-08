module "postgress_bucket" {
  source           = "./minio-bucket"
  bucket_name      = "postgress"
  owner_access_key = module.secret_minio.fields.MINIO_POSTGRESS_ACCESS_KEY
  owner_secret_key = module.secret_minio.fields.MINIO_POSTGRESS_SECRET_KEY
  is_public        = false
}

output "postgress_bucket_outputs" {
  value     = module.postgress_bucket
  sensitive = true
}
