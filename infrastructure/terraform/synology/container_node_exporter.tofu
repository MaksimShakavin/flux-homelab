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
      # No rslave propagation: Synology's Docker root mount isn't shared/slave,
      # so requesting it fails the container.
      volumes = [{
        type      = "bind"
        source    = "/"
        target    = "/host"
        read_only = true
      }]
    }
  }
}
