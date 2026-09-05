module "terraform_bucket" {
  source      = "./garage-bucket"
  bucket_name = "terraform"
}

output "terraform_bucket_outputs" {
  value     = module.terraform_bucket
  sensitive = true
}
