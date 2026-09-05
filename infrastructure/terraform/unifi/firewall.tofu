# Zone-based firewall (UniFi Network 8.x+ / UniFi OS 9.x).
#
# ---------------------------------------------------------------------------
# HISTORY: v1 of this file caused a network outage on 2026-09-04 (restored from
# UniFi backup). Root cause was never confirmed (logging was off), but the
# trigger was pulling the Default/management network into a custom zone and
# slamming default-deny down on everything at once. v2 avoids that:
#   - Default (Proxmox hosts, UniFi device adoption, CONF LEOX) STAYS in the
#     built-in Internal zone and is never managed/fenced here.
#   - Guest reuses the built-in Hotspot zone (the controller auto-assigns
#     is_guest networks there; a custom Guest zone fought it for ownership).
#   - Only Main/Servers/IoT/Cameras become custom zones.
#   - Every policy has logging = true so a staged rollout is observable.
#   - Routed/inter-zone sources match by IP/network, never client MAC (MAC
#     matching is unreliable once traffic is routed through the gateway).
#
# ROLLOUT (do NOT apply blind):
#   1. Apply zones + all allow policies with the zone matrix still permissive.
#   2. Watch Settings -> Security -> firewall logs. Confirm the BGP session
#      (bgp.tf: UDM AS64513 <-> nodes 192.168.20.51-53 AS64514, TCP/179) and
#      the Cilium LB IPs (e.g. 192.168.20.61) stay reachable across the new
#      Gateway<->Servers boundary. If Gateway->Servers drops appear, add an
#      explicit policy before proceeding (see servers zone note below).
#   3. Only then enable default-deny, and only for the custom zones.
#   Run tofu against a LOCAL 1Password Connect (docker-compose in
#   infrastructure/1password-store/) so the apply never depends on the cluster
#   IP it might disrupt.
# ---------------------------------------------------------------------------
#
# Model: default-deny between custom zones. Every cross-zone flow is an
# explicit ALLOW; anything not listed is denied. Inter-zone ALLOWs use
# create_allow_respond = true so the controller adds the established/related
# return rule. The *_to_wan policies OMIT it: the controller rejects
# create_allow_respond when the destination is the External zone
# (api.err.FirewallPolicyCreateRespondTrafficPolicyNotAllowed) since WAN return
# traffic is implicit.

############################
# Built-in zones (lookups) #
############################

# WAN / internet.
data "unifi_firewall_zone" "external" {
  name = "External"
}

# WireGuard clients land here. The controller stores the name as "Vpn" (the UI
# shows "VPN"); the data source match is case-sensitive.
data "unifi_firewall_zone" "vpn" {
  name = "Vpn"
}

# Catch-all LAN zone. Holds the Default network (Proxmox host mgmt, UniFi device
# adoption) and the manual CONF LEOX config network. Left intact and unmanaged;
# referenced only as a policy source/destination.
data "unifi_firewall_zone" "internal" {
  name = "Internal"
}

# Guest network is auto-assigned to the built-in Hotspot zone (is_guest = true).
data "unifi_firewall_zone" "hotspot" {
  name = "Hotspot"
}

# The gateway (UDM) itself. Source zone for gateway-originated traffic such as
# the BGP session to the k8s nodes.
data "unifi_firewall_zone" "gateway" {
  name = "Gateway"
}

#################
# Custom zones  #
#################
# Pulled out of Internal. Default is intentionally NOT among these.

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
# Cameras omitted (unifi_network.cameras has internet_access = false).
# Internal->External and Hotspot->External are UniFi built-in default policies;
# not redefined here. These cover only the custom zones.

resource "unifi_firewall_policy" "main_to_wan" {
  name     = "Main to Internet"
  action   = "ALLOW"
  protocol = "all"
  logging  = true
  # No create_allow_respond for External-destination policies (rejected by the
  # controller; WAN return traffic is implicit).

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

# WireGuard clients reach the internet through the tunnel (full-tunnel).
# Remove for split-tunnel (internal-only) access.
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

# Guest lives in the built-in Hotspot zone.
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

# Pi (192.168.20.3) and in-cluster integrations poll/control IoT devices.
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

# NVR / stream consumers in the Servers zone pull camera feeds.
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
# Internal holds the Default network (Proxmox host mgmt, UniFi UI). Routed
# flows are matched by IP/network, NOT client MAC (MAC matching is unreliable
# for traffic routed through the gateway - the v1 proxmox_to_nas rule used MAC
# and is suspected of never matching).

# Manage Proxmox hosts / UniFi UI from trusted devices on Main.
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

# Manage Proxmox hosts / UniFi UI remotely over WireGuard.
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

# View camera streams remotely over WireGuard.
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

# Homepage in k8s (Servers) polls the Proxmox PVE API at 192.168.0.41:8006.
# Destination scoped to just the three Proxmox management IPs (by resource
# reference, matched as IPs).
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

# Proxmox hosts (Internal) mount NFS on the NAS for VM images (non-critical -
# images only; VM disks are local, k8s<->NAS NFS is intra-Servers). Source
# scoped to the Proxmox IPs, destination to the NAS IP - both by IP, not MAC.
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
# bgp.tf peers the UDM (Gateway zone) with the k8s nodes in the Servers zone on
# TCP/179. When everything was flat in Internal this needed no rule; with
# Servers split out it crosses Gateway->Servers. Whether UniFi implicitly
# allows gateway-originated BGP is unverified - if the firewall log shows
# Gateway->Servers drops (or Cilium LB IPs stop being routed) during rollout,
# enable this policy.
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
