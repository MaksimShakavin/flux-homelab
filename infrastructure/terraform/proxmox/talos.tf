data "unifi_network" "Servers" {
  name = "Servers Trusted"
}

locals {
  // if changing, don't forget to change it in other places. DRY is to hard
  mac_addresses = ["BC:24:11:B5:DD:1F", "BC:24:11:0C:FD:22", "BC:24:11:A8:19:33"]
  # renovate: datasource=docker depName=ghcr.io/siderolabs/installer
  talos_version = "v1.9.5"
}

module "talos-controlplanes" {
  source          = "./talos-node"
  oncreate        = false
  count           = 3
  machine_name    = "k8s-control-${count.index + 1}"
  vmid            = sum([100, count.index])
  target_node     = "proxmox${count.index + 1}"
  iso_path        = "https://factory.talos.dev/image/88d1f7a5c4f1d3aba7df787c448c1d3d008ed29cfb34af53fa0df4336a56040b/${local.talos_version}/nocloud-amd64.iso"
  cpu_cores       = 4
  memory          = 29 * 1024
  vlan_id         = data.unifi_network.Servers.vlan_id
  mac_address     = local.mac_addresses[count.index]
  disks           = [
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
