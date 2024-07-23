resource "proxmox_virtual_environment_vm" "node" {
  name      = var.machine_name
  node_name = var.target_node
  vm_id     = var.vmid

  on_boot         = true
  tablet_device   = false
  timeout_stop_vm = 600
  boot_order      = ["scsi0", "ide0"]

  operating_system {
    type = "l26"
  }

  agent {
    enabled = true
    type    = "virtio"
    timeout = "10s"
  }

  bios = "seabios"

  machine = "q35"

  cpu {
    cores = var.cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.memory
    floating  = var.memory
  }

  scsi_hardware = "virtio-scsi-single"

  dynamic "disk" {
    for_each = var.disks
    content {
      datastore_id = disk.value.datastore_id
      discard      = "on"
      interface    = disk.value.interface
      iothread     = true
      size         = disk.value.size
      file_format  = "raw"
      ssd          = true
    }
  }

  network_device {
    model       = "virtio"
    bridge      = "vmbr0"
    mac_address = var.mac_address
    vlan_id     = var.vlan_id
  }

  cdrom {
    enabled   = true
    file_id   = proxmox_virtual_environment_download_file.talos_img.id
    interface = "ide0"
  }

  hostpci {
    device  = "hostpci0"
    id = "0000:00:02.0"
  }

  lifecycle {
    ignore_changes = [
      cpu["architecture"]
    ]
  }
}

resource "proxmox_virtual_environment_download_file" "talos_img" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.target_node
  url          = var.iso_path
}
