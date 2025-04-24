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

I use **1Password** as the secrets store for my homelab cluster. To execute the IaC scripts that provision the
infrastructure, the [1Password Connect](https://developer.1password.com/docs/connect/) server must be set up separately
with access to the relevant 1Password vault(s). Once the cluster setup is complete, 1Password Connect will be hosted
inside the cluster.

#### 🔧 Temporary 1Password Connect (Outside the Cluster)

Before the cluster is up, we run a temporary instance of the 1Password Connect server locally using Docker Compose.

**Steps:**

1. **Prepare credentials**

   Place your `1password-credentials.json` (downloaded from 1Password) into the following directory:
   ```
   infrastructure/1password-store/1password-credentials.json
   ```

2. **Start the temporary Connect server**

   Run the following from the project root:
   ```bash
   docker-compose -f infrastructure/1password-store/docker-compose.yaml up -d
   ```

3. **Export environment variables**

   - These are required for Terraform and other IaC tools to authenticate with 1Password:
     ```bash
     export OP_CONNECT_HOST=http://localhost:8080
     ```
   - Alternatively, you can update these variables in the
     [`../infrastructure/secrets.sops.yaml`](../infrastructure/secrets.sops.yaml) file, which is decrypted and loaded by the
     automation scripts.

4. **Verify it's running**
   - Visit [http://localhost:8080/health](http://localhost:8080/health) — it should return a `200 OK` response.

💡 Once the Kubernetes cluster is ready, 1Password Connect will be deployed inside the cluster as a permanent service.
The temporary setup is only needed for bootstrapping.

The 1Password vault should contain the following items:
<details>
<summary>1Password Vault Items</summary>

| Item name                 | Fields                                          | Description                                               |
|---------------------------|-------------------------------------------------|-----------------------------------------------------------|
| mino                      | MINIO_ROOT_USER                                 |                                                           |
|                           | MINO_ROOT_PASSWORD                              |                                                           |
|                           | VOLSYNC_RESTIC_PASSWORD                         | rectic repo encryption key                                |
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
3. Set up BGP network .
  - Go to Settings -> Routing -> BGP
  - Create k8s entry with [config file content](../kubernetes/apps/kube-system/cilium)

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
   2. Open the `Synology Container Manager` and run a Docker container using the `minio/minio` image. Ensure that port
      `9000` is forwarded.
2. **Create Minio Buckets:**
   - Use [terraform module](../infrastructure/terraform/minio) to create necessary buckets and users

#### Configure NFS Connections

 **Create a Shared Folder:**
  1. Open the Synology Control Panel and navigate to `Shared Folders`.
  2. Create a shared folder for the Kubernetes cluster.
  3. Go to the folder settings and select `NFS Permissions`.
  4. Add the IP addresses of all Kubernetes nodes. Select `Squash` as `No`.

#### Configure Reverse proxy

1. Go to Config Panel -> Login Portal -> Advanced -> Reverse proxy and add:
   - proxmox.exelent.click -> https 192.168.0.41:8006 with WebSocket custom header
   - sprut.exelent.click -> http 192.168.20.3:7777 with WebSocket custom header
   - minio.exelent.click -> http localhost:9090
2. Go to Config Panel -> Login Portal and add Domain nas.exelent.click
3. Click on Certificates and upload tls.key and tls.crt from Onepassword
4. Click Settings and apply the certificate to added domains

### 7. Set up healthchecks.io

1. Go to [healthchecks.io](https://healthchecks.io), set up account and create healthcheck
2. Copy healthcheck url to 1Password healthchecks object to `ALERTMANAGER_HEARTBEAT_WEBHOOK`

