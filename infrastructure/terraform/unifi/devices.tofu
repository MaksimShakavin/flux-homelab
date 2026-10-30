resource "unifi_device" "us_24_pro" {
  mac = "f4:e2:c6:d0:7a:db"

  name = "USW Pro 24"

  port_override {
    index                  = 13
    autoneg                = true
    flow_control_enabled   = false
    forward                = "customize"
    full_duplex            = false
    isolation              = false
    name                   = "Port 13"
    native_networkconf_id  = unifi_network.servers_trusted.id
    op_mode                = "switch"
    port_keepalive_enabled = false
    setting_preference     = "auto"
    stp_port_mode          = true
    tagged_vlan_mgmt       = "auto"
    egress_rate_limit      = { enabled = false }
    lldpmed                = { enabled = true, notify_enabled = false }
    port_security          = { enabled = false }
    stormctrl = {
      bcast = { enabled = false }
      mcast = { enabled = false }
      ucast = { enabled = false }
    }
  }

  port_override {
    index                  = 19
    aggregate_members      = [19, 20]
    autoneg                = true
    flow_control_enabled   = false
    forward                = "customize"
    full_duplex            = false
    isolation              = false
    name                   = "Port 19"
    native_networkconf_id  = "69982b05a2906b80467887ec"
    op_mode                = "aggregate"
    port_keepalive_enabled = false
    setting_preference     = "manual"
    stp_port_mode          = false
    tagged_vlan_mgmt       = "auto"
    egress_rate_limit      = { enabled = false }
    lldpmed                = { enabled = false, notify_enabled = false }
    port_security          = { enabled = false }
    stormctrl = {
      bcast = { enabled = false }
      mcast = { enabled = false }
      ucast = { enabled = false }
    }
  }

}

resource "unifi_device" "usw_lite_8_poe" {
  mac = "d8:b3:70:9c:96:a6"

  name = "USW Lite 8 PoE"

  port_override {
    index                  = 2
    autoneg                = true
    flow_control_enabled   = false
    forward                = "customize"
    full_duplex            = false
    isolation              = false
    name                   = "Port 2"
    native_networkconf_id  = unifi_network.main.id
    op_mode                = "switch"
    port_keepalive_enabled = false
    setting_preference     = "auto"
    stp_port_mode          = true
    tagged_vlan_mgmt       = "auto"
    egress_rate_limit      = { enabled = false }
    lldpmed                = { enabled = true, notify_enabled = false }
    port_security          = { enabled = false }
    stormctrl = {
      bcast = { enabled = false }
      mcast = { enabled = false }
      ucast = { enabled = false }
    }
  }

  port_override {
    index                  = 3
    autoneg                = true
    flow_control_enabled   = false
    forward                = "customize"
    full_duplex            = false
    isolation              = false
    name                   = "Port 3"
    native_networkconf_id  = unifi_network.main.id
    op_mode                = "switch"
    port_keepalive_enabled = false
    setting_preference     = "auto"
    stp_port_mode          = true
    tagged_vlan_mgmt       = "auto"
    egress_rate_limit      = { enabled = false }
    lldpmed                = { enabled = true, notify_enabled = false }
    port_security          = { enabled = false }
    stormctrl = {
      bcast = { enabled = false }
      mcast = { enabled = false }
      ucast = { enabled = false }
    }
  }

  port_override {
    index                  = 4
    autoneg                = true
    flow_control_enabled   = false
    forward                = "customize"
    full_duplex            = false
    isolation              = false
    name                   = "Port 4"
    native_networkconf_id  = unifi_network.main.id
    op_mode                = "switch"
    poe_mode               = "off"
    port_keepalive_enabled = false
    setting_preference     = "auto"
    stp_port_mode          = true
    tagged_vlan_mgmt       = "auto"
    egress_rate_limit      = { enabled = false }
    lldpmed                = { enabled = true, notify_enabled = false }
    port_security          = { enabled = false }
    stormctrl = {
      bcast = { enabled = false }
      mcast = { enabled = false }
      ucast = { enabled = false }
    }
  }

  port_override {
    index                  = 5
    autoneg                = true
    flow_control_enabled   = false
    forward                = "customize"
    full_duplex            = false
    isolation              = false
    name                   = "Port 5"
    native_networkconf_id  = unifi_network.main.id
    op_mode                = "switch"
    port_keepalive_enabled = false
    setting_preference     = "auto"
    stp_port_mode          = true
    tagged_vlan_mgmt       = "auto"
    egress_rate_limit      = { enabled = false }
    lldpmed                = { enabled = true, notify_enabled = false }
    port_security          = { enabled = false }
    stormctrl = {
      bcast = { enabled = false }
      mcast = { enabled = false }
      ucast = { enabled = false }
    }
  }

  port_override {
    index                  = 6
    autoneg                = true
    flow_control_enabled   = false
    forward                = "customize"
    full_duplex            = false
    isolation              = false
    name                   = "Port 6"
    native_networkconf_id  = unifi_network.main.id
    op_mode                = "switch"
    port_keepalive_enabled = false
    setting_preference     = "auto"
    stp_port_mode          = true
    tagged_vlan_mgmt       = "auto"
    egress_rate_limit      = { enabled = false }
    lldpmed                = { enabled = true, notify_enabled = false }
    port_security          = { enabled = false }
    stormctrl = {
      bcast = { enabled = false }
      mcast = { enabled = false }
      ucast = { enabled = false }
    }
  }

  port_override {
    index                  = 7
    autoneg                = true
    flow_control_enabled   = false
    forward                = "customize"
    full_duplex            = false
    isolation              = false
    name                   = "Port 7"
    native_networkconf_id  = unifi_network.main.id
    op_mode                = "switch"
    port_keepalive_enabled = false
    setting_preference     = "auto"
    stp_port_mode          = true
    tagged_vlan_mgmt       = "auto"
    egress_rate_limit      = { enabled = false }
    lldpmed                = { enabled = true, notify_enabled = false }
    port_security          = { enabled = false }
    stormctrl = {
      bcast = { enabled = false }
      mcast = { enabled = false }
      ucast = { enabled = false }
    }
  }
}
