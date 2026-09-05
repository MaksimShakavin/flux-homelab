module "static_content_bucket" {
  source      = "./garage-bucket"
  bucket_name = "static-content"
  website_access = {
    index_document = "index.html"
    error_document = "error.html"
  }
}

output "static_content_bucket_outputs" {
  value     = module.static_content_bucket
  sensitive = true
}
