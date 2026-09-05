# Default VLAN for UniFi devices and Proxmox nodes that need to access all VLANs
data "unifi_network" "default" {
  name = "Default"
}

resource "unifi_network" "main" {
  name   = "Main"
  subnet = "192.168.10.1/24"
  vlan   = 10

  setting_preference = "manual"
  lte_lan            = false
  multicast_dns      = true
  igmp_snooping      = true

  dhcp_server = {
    enabled     = true
    start       = "192.168.10.100"
    stop        = "192.168.10.200"
    dns_enabled = true
    dns_servers = ["192.168.10.1"]
  }
}

resource "unifi_network" "servers_trusted" {
  name   = "Servers-Trusted"
  subnet = "192.168.20.1/24"
  vlan   = 20

  setting_preference = "manual"
  lte_lan            = false
  multicast_dns      = true
  igmp_snooping      = true

  dhcp_server = {
    enabled     = true
    start       = "192.168.20.100"
    stop        = "192.168.20.200"
    dns_enabled = true
    dns_servers = ["192.168.20.1"]
  }
}

resource "unifi_network" "iot" {
  name   = "IoT"
  subnet = "192.168.30.1/24"
  vlan   = 30

  setting_preference = "manual"
  multicast_dns      = true
  igmp_snooping      = true
  lte_lan            = false

  dhcp_server = {
    enabled     = true
    start       = "192.168.30.100"
    stop        = "192.168.30.200"
    dns_enabled = true
    dns_servers = ["192.168.30.1"]
  }
}

resource "unifi_network" "cameras" {
  name   = "Cameras"
  subnet = "192.168.40.1/24"
  vlan   = 40

  setting_preference = "manual"
  lte_lan            = false
  internet_access    = false
  multicast_dns      = false
  igmp_snooping      = true

  dhcp_server = {
    enabled     = true
    start       = "192.168.40.100"
    stop        = "192.168.40.200"
    dns_enabled = true
    dns_servers = ["192.168.40.1"]
  }
}

resource "unifi_network" "guest" {
  name   = "Guest"
  subnet = "192.168.50.1/24"
  vlan   = 50

  setting_preference = "manual"
  lte_lan            = false
  multicast_dns      = false

  dhcp_server = {
    enabled     = true
    start       = "192.168.50.100"
    stop        = "192.168.50.200"
    dns_enabled = true
    dns_servers = ["1.1.1.1", "8.8.8.8"]
  }
}
