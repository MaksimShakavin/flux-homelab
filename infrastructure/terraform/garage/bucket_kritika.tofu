module "kritika_bucket" {
  source      = "./garage-bucket"
  bucket_name = "kritika"
}

output "kritika_bucket_outputs" {
  value     = module.kritika_bucket
  sensitive = true
}
