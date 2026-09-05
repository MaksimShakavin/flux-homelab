# Prometheus node_exporter deployment on Synology

resource "synology_container_project" "node_exporter" {
  name = "node-exporter"
  run  = true

  services = {
    node-exporter = {
      image        = "quay.io/prometheus/node-exporter:v1.8.2"
      restart      = "unless-stopped"
      network_mode = "host"
      pid          = "host"
      command      = ["--path.rootfs=/host"]
      # No rslave propagation: Synology's Docker root mount is not shared/slave,
      # so requesting it fails the container with "not a shared or slave mount".
      volumes = [{
        type      = "bind"
        source    = "/"
        target    = "/host"
        read_only = true
      }]
    }
  }
}
