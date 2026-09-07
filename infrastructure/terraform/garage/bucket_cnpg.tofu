module "cnpg_bucket" {
  source      = "./garage-bucket"
  bucket_name = "cnpg"
}

output "cnpg_bucket_outputs" {
  value     = module.cnpg_bucket
  sensitive = true
}
