## Prerequisites

### 1. Set up cloudflare
1. Go to [Cloudflare API Tokens](https://dash.cloudflare.com/profile/api-tokens) and create an API Token.
2. Under the `API Tokens` section, click the blue `Create Token` button.
3. Select the `Edit zone DNS` template by clicking the blue `Use template` button.
4. Under `Permissions`, click `+ Add More` and add the following permissions:
  - `Zone - DNS - Edit`
  - `Account - Cloudflare Tunnel - Read`
5. Limit the permissions to specific account and zone resources.
6. Click the blue `Continue to Summary` button and then the blue `Create Token` button.
7. Copy the token and save it to the secrets store under a `CF_API_TOKEN` field.

### 2. Set up secrets store
I use 1Password as the secrets store for my homelab cluster. To execute the IaC scripts that provision the
infrastructure, the [1Password Connect](https://developer.1password.com/docs/connect/) must be set up separately with access
to the 1Password vault. Once the cluster setup is complete, 1Password Connect will be hosted inside the cluster.

Ensure you update `OP_CONNECT_HOST` and `OP_CONNECT_TOKEN` in the [env file](../infrastructure/secrets.sops.yaml).

The 1Password vault should contain the following items:
<details>
<summary>1Password Vault Items</summary>

| Item name                 | Fields                                          | Description                                               |
|---------------------------|-------------------------------------------------|-----------------------------------------------------------|
| mino                      | MINIO_ROOT_USER                                 |                                                           |
|                           | MINO_ROOT_PASSWORD                              |                                                           |
|                           | MINO_LOKI_BUCKET                                |                                                           |
|                           | MINO_LOKI_SECRET_KEY                            |                                                           |
|                           | MINO_LOKI_ACCESS_KEY                            |                                                           |
|                           | MINO_THANOS_BUCKET                              |                                                           |
|                           | MINO_THANOS_SECRET_KEY                          |                                                           |
|                           | MINO_THANOS_ACCESS_KEY                          |                                                           |
| cloudnative-pg            | POSTGRESS_SUPER_USER                            |                                                           |
|                           | POSTGRESS_SUPER_PASS                            |                                                           |
| cloudflare                | CLOUDFLARE_ACCOUNT_TAG                          |                                                           |
|                           | CLOUDFLARE_TUNNEL_SECRET                        |                                                           |
|                           | CLUSTER_CLOUDFLARE_TUNNEL_ID                    |                                                           |
|                           | CLOUDFLARE_HOMEPAGE_TUNNEL_SECRET               |                                                           |
|                           | CF_API_TOKEN                                    |                                                           |
| proxmox                   | username                                        |                                                           |
|                           | password                                        |                                                           |
|                           | HOMEPAGE_PROXMOX_USERNAME                       |                                                           |
|                           | HOMEPAGE_PROXMOX_PASSWORD                       |                                                           |
| actions-runner-controller | ACTION_RUNNER_CONTROLLER_GITHUB_APP_ID          |                                                           |
|                           | ACTION_RUNNER_CONTROLLER_GITHUB_INSTALLATION_ID |                                                           |
|                           | ACTION_RUNNER_CONTROLLER_GITHUB_PRIVATE_KEY     | In a format starting with -----BEGIN RSA PRIVATE KEY----- |
| unifipoller               | username                                        |                                                           |
|                           | password                                        |                                                           |
| discord                   | GATUS_DISCORD_WEBHOOK                           |                                                           |
|                           | ALERTMANAGER_DISCORD_WEBHOOK                    |                                                           |
| gatus                     | GATUS_POSTGRES_USER                             |                                                           |
|                           | GATUS_POSTGRES_PASS                             |                                                           |
| nodered                   | CREDENTIAL_SECRET                               | Used to encrypt nodered secrets                           |
| overseerr                 | OVERSEERR_TOKEN                                 | Used in homepage                                          |
| pihole                    | HOMEPAGE_PI_HOLE_TOKEN                          |                                                           |
| synology                  | HOMEPAGE_SYNOLOGY_USERNAME                      |                                                           |
|                           | HOMEPAGE_SYNOLOGY_PASSWORD                      |                                                           |
| plex                      | PLEX_TOKEN                                      | Used in homepage                                          |
| prowlarr                  | PROWLARR_API_KEY                                | Used in homepage                                          |
|                           | PROWLARR_POSTGRES_USER                          |                                                           |
|                           | PROWLARR_POSTGRES_PASSWORD                      |                                                           |
| sonarr                    | SONARR_API_KEY                                  | Used in homepage                                          |
|                           | SONARR_POSTGRES_USER                            |                                                           |
|                           | SONARR_POSTGRES_PASSWORD                        |                                                           |
| radarr                    | RADARR_API_KEY                                  | Used in homepage                                          |
|                           | RADARR_POSTGRES_USER                            |                                                           |
|                           | RADARR_POSTGRES_PASSWORD                        |                                                           |
| qbittorrent               | username                                        |                                                           |
|                           | password                                        |                                                           |
| grafana                   | GRAFANA_POSTGRESS_USER                          |                                                           |
|                           | GRAFANA_POSTGRESS_PASS                          |                                                           |
| pihole                    | HOMEPAGE_PI_HOLE_TOKEN                          |                                                           |
</details>

### 3. Set up UDM

1. Set up the unifipoller user (TODO docs).
2. Forward port for qBittorrent (TODO docs).

### 4. Get discord token

1. Go to Server settings -> Integrations and create two webhooks:
  - Webhook for Prometheus alerts. Save it to the `ALERTMANAGER_DISCORD_WEBHOOK` item in 1Password.
  - Webhook for Gatus alerts. Save it to the `GATUS_DISCORD_WEBHOOK` item in 1Password.

### 5. Set up pihole and generate token for Homepage

1. Set up Pi-hole on a separate Raspberry Pi.
2. Generate a token for the Homepage widget in Pi-hole and save it to the `HOMEPAGE_PI_HOLE_TOKEN` item in 1Password.

### 6. NAS set up

#### Install and Configure Minio on NAS

1. **Install Synology Container Manager:**
   1. Install the `Synology Container Manager` package from the Package Center.
   2. Open the `Synology Container Manager` and run a Docker container using the `minio/minio` image. Ensure that port `9000` is forwarded.

2. **Create Minio Buckets:**
  - Manually create the following buckets:
    - `cloudnative-pg` for PostgreSQL backups.
    - `loki-bucket` to store logs.
    - `thanos` to store old metrics data with Thanos.
  - Update the corresponding 1Password items with the necessary details.

#### Configure NFS Connections

1. **Create a Shared Folder:**
   1. Open the Synology Control Panel and navigate to `Shared Folders`.
   2. Create a shared folder for the Kubernetes cluster.
   3. Go to the folder settings and select `NFS Permissions`.
   4. Add the IP addresses of all Kubernetes nodes. Select `Squash` as `No`.
