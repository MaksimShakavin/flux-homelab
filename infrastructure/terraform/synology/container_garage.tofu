# Garage S3-compatible object storage deployment on Synology

locals {
  # FileStation API uses share-relative paths (starting at the shared folder),
  # while Docker bind mounts need the physical /volume1 path.
  garage_share_dir = "/docker/garage"
  garage_phys_dir  = "/volume1/docker/garage"
}

module "secret_garage" {
  # Remember to export OP_CONNECT_HOST and OP_CONNECT_TOKEN
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "homelab"
  item   = "garage"
}

resource "synology_filestation_folder" "garage_data" {
  path = "${local.garage_share_dir}/data"
}

resource "synology_filestation_folder" "garage_meta" {
  path = "${local.garage_share_dir}/meta"
}

resource "synology_filestation_file" "garage_config" {
  path = "${local.garage_share_dir}/garage.toml"
  content = templatefile("${path.module}/templates/garage.toml.tpl", {
    rpc_secret  = module.secret_garage.fields.rpc_secret
    admin_token = module.secret_garage.fields.admin_token
  })
}

resource "synology_container_project" "garage" {
  name = "garage"
  run  = true

  depends_on = [
    synology_filestation_folder.garage_data,
    synology_filestation_folder.garage_meta,
    synology_filestation_file.garage_config,
  ]

  networks = {
    garage = {
      driver = "bridge"
    }
  }

  services = {
    garage = {
      image   = "dxflrs/garage:v2.3.0"
      restart = "unless-stopped"
      # The garage image has no ENTRYPOINT and the binary lives at /garage, so
      # the command must include the full path (default CMD is /garage server).
      command = ["/garage", "server"]
      networks = {
        garage = {}
      }
      # Only S3 (3900) and admin (3903) are published; RPC (3901) stays internal.
      ports = [
        {
          target    = 3900
          published = "3900"
        },
        {
          target    = 3903
          published = "3903"
        },
      ]
      environment = {
        RUST_LOG = "garage=info"
      }
      # Bind sources use the physical /volume1 path; depend on the FileStation
      # resources so the folders/file exist before the container starts.
      volumes = [
        {
          type   = "bind"
          source = "${local.garage_phys_dir}/data"
          target = "/data"
        },
        {
          type   = "bind"
          source = "${local.garage_phys_dir}/meta"
          target = "/metadata"
        },
        {
          type      = "bind"
          source    = "${local.garage_phys_dir}/garage.toml"
          target    = "/etc/garage.toml"
          read_only = true
        },
      ]
    }
  }
}
