resource "garage_bucket" "static_content" {
  global_alias = "static-content"

  website_access {
    enabled        = true
    index_document = "index.html"
    error_document = "error.html"
  }
}
