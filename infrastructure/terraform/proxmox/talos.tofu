data "unifi_network" "Servers" {
  name = "Servers-Trusted"
}

locals {
  // if changing, don't forget to change it in other places. DRY is to hard
  mac_addresses = ["BC:24:11:B5:DD:1F", "BC:24:11:0C:FD:22", "BC:24:11:A8:19:33"]
  # renovate: datasource=docker depName=ghcr.io/siderolabs/installer
  talos_version  = "v1.13.10"
  talos_image_id = "b52c537678fcbaa6b894bf1e90894767c17230a605546bef6ce247cd815bc2a4"
}

module "talos-controlplanes" {
  source       = "./talos-node"
  oncreate     = false
  count        = 3
  machine_name = "k8s-control-${count.index + 1}"
  vmid         = sum([100, count.index])
  target_node  = "proxmox${count.index + 1}"
  iso_path     = "https://factory.talos.dev/image/${local.talos_image_id}/${local.talos_version}/nocloud-amd64.iso"
  cpu_cores    = 4
  memory       = 29 * 1024
  vlan_id      = data.unifi_network.Servers.vlan
  mac_address  = local.mac_addresses[count.index]
  disks = [
    {
      datastore_id : "local-lvm"
      interface : "scsi0"
      size : "900"
    },
    {
      datastore_id : "ssd"
      interface : "scsi1"
      size : "900"
    }
  ]
}
