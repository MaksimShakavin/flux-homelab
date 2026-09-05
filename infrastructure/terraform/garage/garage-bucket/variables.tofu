variable "bucket_name" {
  type = string
}

variable "website_access" {
  type = object({
    index_document = string
    error_document = string
  })
  default = null
}
