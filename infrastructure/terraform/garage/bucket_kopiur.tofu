module "kopiur_bucket" {
  source      = "./garage-bucket"
  bucket_name = "kopiur"
}

output "kopiur_bucket_outputs" {
  value     = module.kopiur_bucket
  sensitive = true
}
