variable "name" {
  type = string
}

variable "icon_url" {
  type    = string
  default = ""
}

variable "launch_url" {
  type    = string
  default = ""
}

variable "description" {
  type    = string
  default = ""
}

variable "newtab" {
  type    = bool
  default = true
}

variable "group" {
  type    = string
  default = ""
}

variable "auth_groups" {
  type = list(string)
}

variable "client_id" {
  type = string
}

variable "client_secret" {
  type    = string
  default = null
}

variable "authorization_flow" {
  type = string
}

variable "client_type" {
  type    = string
  default = "confidential"
}

variable "redirect_uris" {
  type = list(string)
}

locals {
  client_secret = (
  var.client_type == "confidential"
  ? var.client_secret != null ? var.client_secret : random_password.client_secret.result
  : null
  )
}
