resource "unifi_client" "Lenovo1" {
  mac  = "6c:4b:90:1d:6b:3f"
  name = "Lenovo 1"
  note = "Proxmox node 1"

  fixed_ip   = "192.168.0.41"
  # dev_id_override = 5254
}

resource "unifi_client" "Lenovo2" {
  mac  = "6c:4b:90:17:df:aa"
  name = "Lenovo 2"
  note = "Proxmox node 2"

  fixed_ip   = "192.168.0.42"
  # dev_id_override = 5254
}

resource "unifi_client" "Lenovo3" {
  mac  = "6c:4b:90:a4:d4:88"
  name = "Lenovo 3"
  note = "Proxmox node 3"

  fixed_ip   = "192.168.0.43"
  # dev_id_override = 5254
}

resource "unifi_client" "raspberrypi" {
  mac  = "d8:3a:dd:d7:7a:b5"
  name = "Raspberry Pi"
  note = "Raspberry Pi 5"

  fixed_ip   = "192.168.20.3"
}

resource "unifi_client" "synology-nas" {
  mac = "90:09:d0:4a:a3:89"
  name = "Synology NAS"
  note = "Synology DS920+"
  fixed_ip   = "192.168.20.5"
}

resource "unifi_client" "apple-tv" {
  mac  = "9c:3e:53:15:97:c0"
  name = "Apple TV"
  note = "Apple TV 4K Living Room"
  fixed_ip = "192.168.10.2"
}

resource "unifi_client" "samsung-tv" {
  mac  = "1c:86:9a:a1:5b:e4"
  name = "Samsung Smart TV"
  note = "TV in Living Room"
  fixed_ip = "192.168.10.3"
}

resource "unifi_client" "jbl-bar" {
  mac  = "28:6f:40:37:7e:d5"
  name = "JBL Bar 1000_A4B5"
  note = "Jbl soundbar connected to TV in Living Room"
  fixed_ip = "192.168.10.4"
  # dev_id_override = 4635
}

resource "unifi_client" "govee-curtain-cabinet" {
  mac  = "60:74:f4:47:1e:b4"
  name = "Govee Curtain H70B1"
  note = "Goove Curtain in Cabinet"
  fixed_ip = "192.168.30.2"
  # dev_id_override = 5522
}

resource "unifi_client" "govee-curtain-tree" {
  mac  = "60:74:f4:40:c3:b6"
  name = "Govee Curtain H70B1"
  note = "Goove Curtain in Living Room near TV"
  fixed_ip = "192.168.30.3"
  # dev_id_override = 5522
}

resource "unifi_client" "govee-curtain-table" {
  mac  = "60:74:f4:4f:50:00"
  name = "Govee Curtain H70B1"
  note = "Goove Curtain near the table"
  fixed_ip = "192.168.30.4"
  # dev_id_override = 5522
}

resource "unifi_client" "govee-tv-backlight" {
  mac  = "d4:ad:fc:de:93:46"
  name = "Govee Backlight H605C"
  note = "Goove Backlight for TV in Living Room"
  fixed_ip = "192.168.30.5"
  # dev_id_override = 5084
}

# resource "unifi_client" "printer" {
#   mac  = "24:fb:e3:09:39:0f"
#   name = "Printer HP LaserJet M140w"
#   fixed_ip = "192.168.30.6"
#   network_id = unifi_network.iot.id
# }

resource "unifi_client" "vacuum-cleaner" {
  mac  = "b0:4a:39:3f:7f:dd"
  name = "Roborock S7 Pro Ultra"
  note = "roborock-vacuum-a62"
  fixed_ip = "192.168.30.7"
  network_id = unifi_network.iot.id
  # dev_id_override = 2912
}

resource "unifi_client" "humidifier" {
  mac  = "ec:4d:3e:7e:01:d6"
  name = "Smartmi Evaporative Humidifier 2"
  note = "zhimi-humidifier-ca4_mibt01D6"
  fixed_ip = "192.168.30.8"
  # dev_id_override = 4865
}

resource "unifi_client" "air-purifier" {
  mac  = "00:08:dc:58:bd:ef"
  name = "COWAY Airmega 300S"
  note = "Air purifier in living room"
  fixed_ip = "192.168.30.9"
  # dev_id_override = 3486
}

resource "unifi_client" "yandex-alice" {
  mac  = "b8:87:6e:1b:62:d5"
  name = "Yandex Alice Mini"
  note = "Yandex Alice Mini smart speaker in kitchen"
  fixed_ip = "192.168.30.10"
}

resource "unifi_client" "anker-charger" {
  mac  = "f4:9d:8a:5e:b6:37"
  name = "Anker Prime 250W Charger"
  fixed_ip = "192.168.30.11"
}

resource "unifi_client" "birdfy-feeder" {
  mac  = "b4:61:e9:03:9a:2a"
  name = "Birdfy Feeder"
  fixed_ip = "192.168.30.12"
}

resource "unifi_client" "govee-floor-lamp" {
  mac  = "5c:e7:53:82:81:dc"
  name = "Govee Uplighter Floor Lamp"
  fixed_ip = "192.168.30.13"
  # dev_id_override = 5262
}

resource "unifi_client" "govee-tv-light-bars" {
  mac  = "98:17:3c:cd:bf:84"
  name = "Govee RGBIC TV Light Bars"
  fixed_ip = "192.168.30.14"
  # dev_id_override = 5519
}

resource "unifi_client" "govee-ai-sync-box-tv" {
  mac  = "88:3b:dc:15:00:9e"
  name = "Govee AI Sync Box TV"
  fixed_ip = "192.168.30.15"
  # dev_id_override = 5084
}

resource "unifi_client" "govee-ai-sync-box-pc" {
  mac  = "cc:b8:5e:b4:1b:7f"
  name = "Govee AI Sync Box TV"
  fixed_ip = "192.168.30.16"
  # dev_id_override = 5084
}

resource "unifi_client" "g6-instant" {
  mac  = "84:78:48:28:7f:5c"
  name = "G6 Instant"
  fixed_ip = "192.168.40.2"
}
