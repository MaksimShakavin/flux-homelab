data "unifi_ap_group" "default" {
  name = "All APs"
}

data "unifi_client_qos_rate" "default" {
  name = "Default"
}

resource "unifi_wlan" "main" {
  name       = "Masik Home"
  passphrase = module.secret_unifi.fields.MAIN_WIFI_PASSWORD
  security   = "wpapsk"
  uapsd = true
  mac_filter = {
    enabled = false #default value of controller, not setting it causes errors on apply
  }
  minimum_data_rate_2g_kbps = 1000 #default value of controller, not setting it causes errors on apply
  minimum_data_rate_5g_kbps = 6000 #default value of controller, not setting it causes errors on apply

  # enable WPA2/WPA3 support
  wpa3_support    = true
  wpa3_transition = true
  pmf_mode        = "optional"
  bss_transition = true
  multicast_enhance = true
  # TODO test it
  # fast_roaming_enabled = true

  network_id    = unifi_network.main.id
  ap_group_ids  = [data.unifi_ap_group.default.id]
  user_group_id = data.unifi_client_qos_rate.default.id
}

resource "unifi_wlan" "iot" {
  name       = "Masik IOT"
  passphrase = module.secret_unifi.fields.IOT_WIFI_PASSWORD
  security   = "wpapsk"
  uapsd = true
  mac_filter = {
    enabled = false
  }
  minimum_data_rate_2g_kbps = 1000
  minimum_data_rate_5g_kbps = 6000

  hide_ssid  = true
  no2ghz_oui = false #
  wlan_band  = "2g"
  wlan_bands = ["2g"]
  multicast_enhance = true
  bss_transition = false

  network_id    = unifi_network.iot.id
  ap_group_ids  = [data.unifi_ap_group.default.id]
  user_group_id = data.unifi_client_qos_rate.default.id
}

resource "unifi_wlan" "guest" {
  name       = "Masik's Guests"
  passphrase = module.secret_unifi.fields.GUEST_WIFI_PASSWORD
  security   = "wpapsk"
  uapsd = true
  mac_filter = {
    enabled = false
  }
  minimum_data_rate_2g_kbps = 1000
  minimum_data_rate_5g_kbps = 6000

  is_guest   = true
  wpa3_support    = true
  wpa3_transition = true
  pmf_mode        = "optional"

  network_id    = unifi_network.guest.id
  ap_group_ids  = [data.unifi_ap_group.default.id]
  user_group_id = data.unifi_client_qos_rate.default.id
}

resource "unifi_wlan" "cameras" {
  name       = "Masik Cameras"
  passphrase = module.secret_unifi.fields.CAMERAS_WIFI_PASSWORD
  security   = "wpapsk"
  uapsd = true
  mac_filter = {
    enabled = false
  }
  minimum_data_rate_2g_kbps = 1000
  minimum_data_rate_5g_kbps = 6000

  hide_ssid  = true
  wlan_band  = "5g"
  wlan_bands = ["5g"]
  l2_isolation = true
  bss_transition = true
  no2ghz_oui = false # there is only one band, but provider set's default value(true) on apply, which is incorrect

  network_id    = unifi_network.cameras.id
  ap_group_ids  = [data.unifi_ap_group.default.id]
  user_group_id = data.unifi_client_qos_rate.default.id

}
