# Portainer agent deployment on Synology
# The in-cluster Portainer server connects to this agent as a Docker Standalone
# environment at nas.exelent.click:9001.

resource "synology_container_project" "portainer_agent" {
  name = "portainer-agent"
  run  = true

  services = {
    portainer_agent = {
      image   = "portainer/agent:2.45.0"
      restart = "unless-stopped"
      ports = [{
        target    = 9001
        published = "9001"
      }]
      volumes = [
        {
          type   = "bind"
          source = "/var/run/docker.sock"
          target = "/var/run/docker.sock"
        },
        {
          type   = "bind"
          source = "/volume1/@docker/volumes"
          target = "/var/lib/docker/volumes"
        },
      ]
    }
  }
}
