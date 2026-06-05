locals {
  wan = "wan3"
}

resource "unifi_dynamic_dns" "cloudflare" {
  service = "cloudflare"

  host_name = "homevpn.exelent.click"

  login    = "exelent.click"
  password = module.secret_cloudflare.fields.CF_API_TOKEN
}

resource "unifi_vpn_server" "wireguard" {
  name        = "WireGuard"
  enabled     = true
  subnet      = "192.168.200.1/24"
  dns = {
    enabled = true
    servers = ["192.168.200.1"]
  }
  wan = {
    interface = local.wan
    ip = "any"
  }
  wireguard = {
    private_key = module.secret_unifi.fields.WIREGUARD_PRIVATE_KEY
    port        = 51820
  }
}
