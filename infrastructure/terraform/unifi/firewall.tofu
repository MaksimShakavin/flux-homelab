# Zone-based firewall (UniFi Network 8.x+ / UniFi OS 9.x).
# Default-deny between custom zones; every cross-zone flow is an explicit ALLOW.
# Inter-zone ALLOWs set create_allow_respond for the return rule; the *_to_wan
# policies omit it because the controller rejects it for External destinations.

############################
# Built-in zones (lookups) #
############################

data "unifi_firewall_zone" "external" {
  name = "External"
}

# Controller stores the name as "Vpn" (UI shows "VPN"); match is case-sensitive.
data "unifi_firewall_zone" "vpn" {
  name = "Vpn"
}

# Default network stays here, unmanaged; referenced only as policy source/dest.
data "unifi_firewall_zone" "internal" {
  name = "Internal"
}

# Guest networks auto-assign to the built-in Hotspot zone (is_guest = true).
data "unifi_firewall_zone" "hotspot" {
  name = "Hotspot"
}

data "unifi_firewall_zone" "gateway" {
  name = "Gateway"
}

#################
# Custom zones  #
#################

resource "unifi_firewall_zone" "main" {
  name        = "Main"
  network_ids = [unifi_network.main.id] # VLAN 10 - trusted personal devices, TVs
}

resource "unifi_firewall_zone" "servers" {
  name        = "Servers"
  network_ids = [unifi_network.servers_trusted.id] # VLAN 20 - k8s, NAS, Pi
}

resource "unifi_firewall_zone" "iot" {
  name        = "IoT"
  network_ids = [unifi_network.iot.id] # VLAN 30 - smart-home devices
}

resource "unifi_firewall_zone" "cameras" {
  name        = "Cameras"
  network_ids = [unifi_network.cameras.id] # VLAN 40 - cameras (no internet)
}

###############################
# Internet access (-> WAN)    #
###############################
# Cameras omitted (internet_access = false). Internal/Hotspot -> External are
# UniFi built-in defaults; only the custom zones are covered here.

resource "unifi_firewall_policy" "main_to_wan" {
  name     = "Main to Internet"
  action   = "ALLOW"
  protocol = "all"
  logging  = true

  source = {
    zone_id         = unifi_firewall_zone.main.id
    matching_target = "ANY"
  }
  destination = {
    zone_id         = data.unifi_firewall_zone.external.id
    matching_target = "ANY"
  }
}

resource "unifi_firewall_policy" "servers_to_wan" {
  name     = "Servers to Internet"
  action   = "ALLOW"
  protocol = "all"
  logging  = true

  source = {
    zone_id         = unifi_firewall_zone.servers.id
    matching_target = "ANY"
  }
  destination = {
    zone_id         = data.unifi_firewall_zone.external.id
    matching_target = "ANY"
  }
}

resource "unifi_firewall_policy" "iot_to_wan" {
  name     = "IoT to Internet"
  action   = "ALLOW"
  protocol = "all"
  logging  = true

  source = {
    zone_id         = unifi_firewall_zone.iot.id
    matching_target = "ANY"
  }
  destination = {
    zone_id         = data.unifi_firewall_zone.external.id
    matching_target = "ANY"
  }
}

# Full-tunnel; remove for split-tunnel (internal-only) access.
resource "unifi_firewall_policy" "vpn_to_wan" {
  name     = "VPN to Internet"
  action   = "ALLOW"
  protocol = "all"
  logging  = true

  source = {
    zone_id         = data.unifi_firewall_zone.vpn.id
    matching_target = "ANY"
  }
  destination = {
    zone_id         = data.unifi_firewall_zone.external.id
    matching_target = "ANY"
  }
}

###############################
# Trusted -> Servers          #
###############################

resource "unifi_firewall_policy" "main_to_servers" {
  name                 = "Main to Servers"
  description          = "Trusted devices reach k8s ingress, NAS, DNS."
  action               = "ALLOW"
  protocol             = "all"
  logging              = true
  create_allow_respond = true

  source = {
    zone_id         = unifi_firewall_zone.main.id
    matching_target = "ANY"
  }
  destination = {
    zone_id         = unifi_firewall_zone.servers.id
    matching_target = "ANY"
  }
}

resource "unifi_firewall_policy" "vpn_to_servers" {
  name                 = "VPN to Servers"
  description          = "Remote WireGuard clients reach internal services."
  action               = "ALLOW"
  protocol             = "all"
  logging              = true
  create_allow_respond = true

  source = {
    zone_id         = data.unifi_firewall_zone.vpn.id
    matching_target = "ANY"
  }
  destination = {
    zone_id         = unifi_firewall_zone.servers.id
    matching_target = "ANY"
  }
}

###############################
# Main -> device / guest zones#
###############################

resource "unifi_firewall_policy" "main_to_iot" {
  name                 = "Main to IoT"
  description          = "Control smart-home devices from trusted devices."
  action               = "ALLOW"
  protocol             = "all"
  logging              = true
  create_allow_respond = true

  source = {
    zone_id         = unifi_firewall_zone.main.id
    matching_target = "ANY"
  }
  destination = {
    zone_id         = unifi_firewall_zone.iot.id
    matching_target = "ANY"
  }
}

resource "unifi_firewall_policy" "main_to_cameras" {
  name                 = "Main to Cameras"
  description          = "View camera streams from trusted devices."
  action               = "ALLOW"
  protocol             = "all"
  logging              = true
  create_allow_respond = true

  source = {
    zone_id         = unifi_firewall_zone.main.id
    matching_target = "ANY"
  }
  destination = {
    zone_id         = unifi_firewall_zone.cameras.id
    matching_target = "ANY"
  }
}

resource "unifi_firewall_policy" "main_to_guest" {
  name                 = "Main to Guest"
  description          = "Trusted devices reach guest-zone devices."
  action               = "ALLOW"
  protocol             = "all"
  logging              = true
  create_allow_respond = true

  source = {
    zone_id         = unifi_firewall_zone.main.id
    matching_target = "ANY"
  }
  destination = {
    zone_id         = data.unifi_firewall_zone.hotspot.id
    matching_target = "ANY"
  }
}

###############################
# Servers -> device zones     #
###############################

resource "unifi_firewall_policy" "servers_to_iot" {
  name                 = "Servers to IoT"
  description          = "Home automation (Pi / k8s) reaches IoT devices."
  action               = "ALLOW"
  protocol             = "all"
  logging              = true
  create_allow_respond = true

  source = {
    zone_id         = unifi_firewall_zone.servers.id
    matching_target = "ANY"
  }
  destination = {
    zone_id         = unifi_firewall_zone.iot.id
    matching_target = "ANY"
  }
}

resource "unifi_firewall_policy" "servers_to_cameras" {
  name                 = "Servers to Cameras"
  description          = "NVR / stream consumers pull camera feeds."
  action               = "ALLOW"
  protocol             = "all"
  logging              = true
  create_allow_respond = true

  source = {
    zone_id         = unifi_firewall_zone.servers.id
    matching_target = "ANY"
  }
  destination = {
    zone_id         = unifi_firewall_zone.cameras.id
    matching_target = "ANY"
  }
}

###############################
# Custom <-> Internal         #
###############################
# Routed flows match by IP/network, not client MAC (MAC is unreliable once
# traffic is routed through the gateway).

resource "unifi_firewall_policy" "main_to_internal" {
  name                 = "Main to Internal"
  description          = "Reach Proxmox / UniFi UI from trusted devices."
  action               = "ALLOW"
  protocol             = "all"
  logging              = true
  create_allow_respond = true

  source = {
    zone_id         = unifi_firewall_zone.main.id
    matching_target = "ANY"
  }
  destination = {
    zone_id         = data.unifi_firewall_zone.internal.id
    matching_target = "ANY"
  }
}

resource "unifi_firewall_policy" "vpn_to_internal" {
  name                 = "VPN to Internal"
  description          = "Remote admin of Proxmox / UniFi UI over WireGuard."
  action               = "ALLOW"
  protocol             = "all"
  logging              = true
  create_allow_respond = true

  source = {
    zone_id         = data.unifi_firewall_zone.vpn.id
    matching_target = "ANY"
  }
  destination = {
    zone_id         = data.unifi_firewall_zone.internal.id
    matching_target = "ANY"
  }
}

resource "unifi_firewall_policy" "vpn_to_cameras" {
  name                 = "VPN to Cameras"
  description          = "Remote camera viewing over WireGuard."
  action               = "ALLOW"
  protocol             = "all"
  logging              = true
  create_allow_respond = true

  source = {
    zone_id         = data.unifi_firewall_zone.vpn.id
    matching_target = "ANY"
  }
  destination = {
    zone_id         = unifi_firewall_zone.cameras.id
    matching_target = "ANY"
  }
}

resource "unifi_firewall_policy" "servers_to_proxmox" {
  name                 = "Servers to Proxmox"
  description          = "Homepage / metrics poll the Proxmox PVE API."
  action               = "ALLOW"
  protocol             = "all"
  logging              = true
  create_allow_respond = true

  source = {
    zone_id         = unifi_firewall_zone.servers.id
    matching_target = "ANY"
  }
  destination = {
    zone_id         = data.unifi_firewall_zone.internal.id
    matching_target = "IP"
    ips = [
      unifi_client.Lenovo1.fixed_ip,
      unifi_client.Lenovo2.fixed_ip,
      unifi_client.Lenovo3.fixed_ip,
    ]
  }
}

resource "unifi_firewall_policy" "proxmox_to_nas" {
  name                 = "Proxmox to NAS"
  description          = "Proxmox NFS to Synology for VM images."
  action               = "ALLOW"
  protocol             = "all"
  logging              = true
  create_allow_respond = true

  source = {
    zone_id         = data.unifi_firewall_zone.internal.id
    matching_target = "IP"
    ips = [
      unifi_client.Lenovo1.fixed_ip,
      unifi_client.Lenovo2.fixed_ip,
      unifi_client.Lenovo3.fixed_ip,
    ]
  }
  destination = {
    zone_id         = unifi_firewall_zone.servers.id
    matching_target = "IP"
    ips             = [unifi_client.synology-nas.fixed_ip]
  }
}

###############################
# Gateway -> Servers (BGP)    #
###############################
# Enable only if firewall logs show Gateway->Servers BGP (TCP/179) drops or
# Cilium LB IPs stop being routed; UniFi may allow gateway BGP implicitly.
#
# resource "unifi_firewall_policy" "gateway_to_servers_bgp" {
#   name                 = "Gateway to Servers BGP"
#   description          = "UDM <-> k8s node BGP session (bgp.tf)."
#   action               = "ALLOW"
#   protocol             = "tcp"
#   logging              = true
#   create_allow_respond = true
#
#   source = {
#     zone_id         = data.unifi_firewall_zone.gateway.id
#     matching_target = "ANY"
#   }
#   destination = {
#     zone_id            = unifi_firewall_zone.servers.id
#     matching_target    = "IP"
#     ips                = ["192.168.20.51", "192.168.20.52", "192.168.20.53"]
#     port               = "179"
#     port_matching_type = "SPECIFIC"
#   }
# }
