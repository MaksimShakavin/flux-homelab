variable "machine_name" {
  type = string
}

variable "mac_address" {
  type = string
}

variable "vmid" {
  type    = number
  default = 0
}

variable "target_node" {
  type = string
}

variable "iso_path" {
  type    = string
  default = ""
}

variable "oncreate" {
  type    = bool
  default = true
}

variable "startup" {
  type    = string
  default = ""
}

variable "cpu_cores" {
  type    = number
  default = 1
}

variable "memory" {
  type    = number
  default = 1024
}

variable "vlan_id" {
  type    = number
  default = 0
}

variable "disks" {
  type = list(object({
    datastore_id  = string
    interface     = string
    size          = string
  }))
  default = []
}
