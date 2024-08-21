#module "thanos_bucket" {
#  source           = "./minio-bucket"
#  bucket_name      = "thanos"
#  owner_access_key = module.secret_minio.fields.MINIO_THANOS_ACCESS_KEY
#  owner_secret_key = module.secret_minio.fields.MINIO_THANOS_SECRET_KEY
#  is_public        = false
#}
#
#output "thanos_bucket_outputs" {
#  value     = module.thanos_bucket
#  sensitive = true
#}
