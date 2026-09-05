## Raw config mode
resource "unifi_bgp" "k8s" {
  description      = "K8s bgp"
  enabled          = true
  upload_file_name = "bgp.conf"

  config = <<EOF
router bgp 64513
  bgp router-id 192.168.0.1
  no bgp ebgp-requires-policy

  neighbor k8s peer-group
  neighbor k8s remote-as 64514

  neighbor 192.168.20.51 peer-group k8s
  neighbor 192.168.20.52 peer-group k8s
  neighbor 192.168.20.53 peer-group k8s

  address-family ipv4 unicast
    neighbor k8s next-hop-self
    neighbor k8s soft-reconfiguration inbound
  exit-address-family
exit
EOF
}
