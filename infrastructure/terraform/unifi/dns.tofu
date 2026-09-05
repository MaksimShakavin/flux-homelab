resource "unifi_dns_record" "nas" {
  name        = "nas.exelent.click"
  enabled     = true
  record_type = "A"
  value       = unifi_client.synology-nas.fixed_ip
}

resource "unifi_dns_record" "sprut" {
  name        = "sprut.exelent.click"
  enabled     = true
  record_type = "CNAME"
  value       = unifi_dns_record.nas.name
}

resource "unifi_dns_record" "unifi" {
  name        = "unifi.exelent.click"
  enabled     = true
  record_type = "CNAME"
  value       = unifi_dns_record.nas.name
}

resource "unifi_dns_record" "minio" {
  name        = "minio.exelent.click"
  enabled     = true
  record_type = "CNAME"
  value       = unifi_dns_record.nas.name
}

resource "unifi_dns_record" "minio_content" {
  name        = "minio-content.exelent.click"
  enabled     = true
  record_type = "CNAME"
  value       = unifi_dns_record.nas.name
}

resource "unifi_dns_record" "proxmox" {
  name        = "proxmox.exelent.click"
  enabled     = true
  record_type = "CNAME"
  value       = unifi_dns_record.nas.name
}

resource "unifi_dns_record" "garage_admin" {
  name        = "garage-admin.exelent.click"
  enabled     = true
  record_type = "CNAME"
  value       = unifi_dns_record.nas.name
}

resource "unifi_dns_record" "garage_s3" {
  name        = "garage-s3.exelent.click"
  enabled     = true
  record_type = "CNAME"
  value       = unifi_dns_record.nas.name
}

resource "unifi_dns_record" "garage_static" {
  name        = "garage-static.exelent.click"
  enabled     = true
  record_type = "CNAME"
  value       = unifi_dns_record.nas.name
}
