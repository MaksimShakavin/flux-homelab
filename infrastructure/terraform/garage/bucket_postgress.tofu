module "postgress_bucket" {
  source      = "./garage-bucket"
  bucket_name = "postgress"
}

output "postgress_bucket_outputs" {
  value     = module.postgress_bucket
  sensitive = true
}
