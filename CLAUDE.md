# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Kubernetes homelab cluster managed through GitOps using FluxCD. The infrastructure runs on Talos Linux nodes hosted in Proxmox VMs. Infrastructure provisioning is managed through Terraform and Ansible, while Kubernetes application deployments are handled by FluxCD syncing from this Git repository.

## Key Technologies

- **Talos Linux**: Immutable Kubernetes-focused Linux distribution running on all cluster nodes
- **FluxCD**: GitOps operator that syncs Kubernetes manifests from this repository to the cluster
- **Proxmox**: Virtualization platform hosting the Talos VMs
- **Terraform**: Infrastructure as Code for provisioning Proxmox VMs, MinIO buckets, UniFi network configuration, and Authentik
- **talhelper**: Helper tool for generating Talos machine configurations from `talconfig.yaml`
- **SOPS**: Secret encryption using age keys; secrets are encrypted before committing to Git
- **1Password Connect**: Secrets management for Kubernetes via External Secrets Operator

## Architecture

### Directory Structure

- `kubernetes/` - All Kubernetes manifests and configuration
  - `apps/` - Application deployments organized by namespace (default, database, observability, storage, network, etc.)
  - `bootstrap/` - Scripts and Talos configuration for cluster bootstrapping
  - `flux/` - FluxCD configuration and cluster-level Kustomizations
- `infrastructure/` - IaC configuration outside of Kubernetes
  - `terraform/` - Terraform modules for Proxmox, MinIO, UniFi, Authentik
  - `ansible/` - Ansible playbooks for Proxmox host configuration
- `.taskfiles/` - Task-specific Taskfile includes for go-task
- `docs/` - Documentation for setup, prerequisites, and how-to guides

### Bootstrap Flow

1. Proxmox hosts are configured via Ansible (`task ansible:proxmox-setup`)
2. Talos VMs are provisioned via Terraform
3. Talos cluster is bootstrapped via talhelper (`task bootstrap:talos`)
4. FluxCD and core apps are installed (`task bootstrap:apps`)
5. FluxCD continuously syncs applications from `kubernetes/apps/` to the cluster

### Secrets Management

- **SOPS encryption**: `.sops.yaml` defines encryption rules using age key
  - Talos secrets: `talos/*.sops.yaml` files
  - Kubernetes secrets: `kubernetes/**/*.sops.yaml` files (encrypted on `data` and `stringData` fields only)
  - Age key file: `age.key` (gitignored, required for decryption)
- **1Password Connect**: Used as the upstream secrets store for Kubernetes via External Secrets Operator
  - Temporary Connect server runs locally via Docker Compose during initial setup
  - After cluster bootstrap, 1Password Connect runs inside the cluster
  - Environment variables required: `OP_CONNECT_HOST`, `OP_CONNECT_TOKEN`

### Cluster Configuration

- **Cluster name**: `home-kubernetes`
- **Control plane**: 3 nodes (k8s-control-1, k8s-control-2, k8s-control-3)
- **Node IPs**: 192.168.20.51-53
- **VIP endpoint**: 192.168.20.60:6443
- **CNI**: Cilium (Talos built-in CNI is disabled)
- **Storage**: Longhorn with nvme and ssd disk configurations per node
- **Pod CIDR**: 10.69.0.0/16
- **Service CIDR**: 10.96.0.0/16

## Common Commands

All commands are executed via [go-task](https://taskfile.dev). Run `task` to list all available tasks.

### Kubernetes Operations

```sh
# View all available tasks
task

# Browse a PVC (mounts it to a temporary pod)
task kubernetes:browse-pvc NS=default CLAIM=my-pvc

# Open a shell to a node
task kubernetes:node-shell NODE=k8s-control-1

# Clean up failed/pending/succeeded pods
task kubernetes:cleanse-pods

# Gather cluster resources (useful for troubleshooting)
task kubernetes:resources

# Upgrade Actions Runner Controller
task kubernetes:upgrade-arc
```

### Talos Operations

```sh
# Generate Talos configuration from talconfig.yaml
task talos:generate-config

# Apply Talos config to a specific node
task talos:apply-node IP=192.168.20.51

# Upgrade Talos on a node
task talos:upgrade-node IP=192.168.20.51

# Upgrade Kubernetes version
task talos:upgrade-k8s

# Reset cluster (DESTRUCTIVE - will prompt for confirmation)
task talos:reset
```

### Kopiur (Backup) Operations

PVC backups are handled by the [kopiur](https://github.com/home-operations/kopiur) operator (Kopia
under the hood), which lives in the `storage` namespace and writes to a single shared repository on
Garage S3. Each app that opts in lists `../../../../components/kopiur/backup` in its `ks.yaml` and sets
`KOPIUR_CAPACITY` (plus `KOPIUR_PUID`/`KOPIUR_PGID` when the app doesn't run as 1000). The component
renders, per app: a `SnapshotPolicy`, a `SnapshotSchedule` (`H * * * *`, hashed per app), a `Restore`,
and the `PersistentVolumeClaim` (populated from the latest snapshot via `dataSourceRef: Restore/<app>`).

CRs live in the **app's own namespace** (e.g. `default`), not `storage`. The short name `snapshot`
resolves to Longhorn's CRD — always use the fully-qualified `snapshots.kopiur.home-operations.com`.

```sh
# List backups / their state (Succeeded CRs are garbage-collected; the kopia data persists)
kubectl get snapshots.kopiur.home-operations.com -A
kubectl get snapshotschedule,snapshotpolicy,restore.kopiur.home-operations.com -A

# Trigger an on-demand snapshot of an app (in the APP's namespace, referencing its policy)
kubectl apply -f - <<EOF
apiVersion: kopiur.home-operations.com/v1alpha1
kind: Snapshot
metadata:
  name: <app>-manual
  namespace: default
spec:
  policyRef:
    name: <app>
EOF
kubectl -n default get snapshots.kopiur.home-operations.com <app>-manual -w  # wait for Succeeded

# Restore an app's PVC fresh from the latest kopia snapshot (destructive reseed).
# The populator only runs at PVC creation, so the PVC must be recreated:
kubectl -n default scale deploy/<app> --replicas 0          # stop writes
# (optional) take a final manual Snapshot here for zero-drift, wait Succeeded
kubectl -n default delete pvc <app>                         # ensure PV reclaimPolicy=Retain first if you want a fallback
# Flux re-renders the PVC (dataSourceRef: Restore/<app>) -> populator restores from kopia:
flux reconcile kustomization <app> -n default
kubectl -n default scale deploy/<app> --replicas 1

# Verify the operator + admission webhook are healthy
kubectl -n storage get pods -l app.kubernetes.io/name=kopiur
kubectl -n storage get clusterrepository nas
```

> Legacy note: PVCs were previously backed up by VolSync (restic, per-app MinIO buckets at
> `s3://192.168.20.5:9000/<app>`). VolSync was decommissioned; the old restic buckets remain in MinIO
> as a cold archive (readable by reinstalling VolSync). MinIO creds are in the 1Password `minio` item.

### Bootstrap Operations

```sh
# Bootstrap Talos cluster (initial setup only)
task bootstrap:talos

# Bootstrap Kubernetes applications via FluxCD
task bootstrap:apps
```

### Ansible Operations

```sh
# Set up Proxmox hosts (SSH keys, updates, GPU passthrough)
task ansible:proxmox-setup

# Upgrade Proxmox packages
task ansible:proxmox-apt-upgrade
```

### Talosctl Commands

Talosctl requires the `--talosconfig` and `--nodes` flags for most operations:

```sh
# Health check
talosctl --talosconfig=./kubernetes/bootstrap/talos/clusterconfig/talosconfig --nodes=192.168.20.51 health

# Reset node ephemeral storage (clears local hostpath PVs)
talosctl --talosconfig=./kubernetes/bootstrap/talos/clusterconfig/talosconfig --nodes=192.168.20.51 reset --system-labels-to-wipe EPHEMERAL
```

### Environment Variables

Several tasks require environment variables to be set:

- `KUBECONFIG`: Path to kubeconfig file (defaults to `./kubeconfig`)
- `SOPS_AGE_KEY_FILE`: Path to age key file (defaults to `./age.key`)
- `OP_CONNECT_HOST`: 1Password Connect server URL (e.g., `http://localhost:8080`)
- `OP_CONNECT_TOKEN`: 1Password Connect API token

These are configured in the root `Taskfile.yaml` but may need to be exported for Terraform operations.

## Working with Secrets

### Encrypting Secrets

SOPS is configured via `.sops.yaml`. To encrypt a file:

```sh
sops --encrypt --in-place path/to/secret.yaml
```

### Decrypting Secrets

```sh
sops --decrypt path/to/secret.sops.yaml
```

### Editing Encrypted Secrets

```sh
sops path/to/secret.sops.yaml
```

SOPS will decrypt the file in your editor and re-encrypt on save.

## Terraform Workflow

Terraform modules are located in `infrastructure/terraform/`:

- `proxmox/` - Proxmox VM provisioning (not currently used; VMs created manually)
- `minio/` - MinIO bucket creation
- `unifi/` - UniFi network configuration (VLANs, firewall, DNS, clients, etc.)
- `authentik/` - Authentik SSO configuration

### Running Terraform

```sh
cd infrastructure/terraform/<module>

# Initialize (first time or after changing backend)
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply
```

### Terraform State

Terraform state is stored in MinIO S3-compatible storage. The backend configuration is commented out by default in `main.tf` files. After MinIO buckets are created, uncomment the backend block and run `terraform init -migrate-state` to migrate local state to MinIO.

## FluxCD Architecture

FluxCD is installed in the `flux-system` namespace and watches this Git repository for changes.

- **Root Kustomization**: `kubernetes/flux/cluster/ks.yaml` defines the `cluster-apps` Kustomization
- **App Structure**: Applications are organized by namespace in `kubernetes/apps/`
- **HelmRelease Defaults**: Cluster-wide HelmRelease patches are applied via the root Kustomization
  - CRDs: CreateReplace strategy
  - Install: RetryOnFailure
  - Upgrade: RemediateOnFailure with 2 retries
  - Rollback: cleanupOnFail and recreate enabled

### FluxCD Commands

```sh
# View all Flux resources
flux get all -A

# Reconcile a Kustomization
flux reconcile kustomization <name> -n flux-system

# Reconcile a HelmRelease
flux reconcile helmrelease <name> -n <namespace>

# Suspend a resource
flux suspend kustomization <name> -n flux-system

# Resume a resource
flux resume kustomization <name> -n flux-system
```

## Network Configuration

- **Router**: UniFi UDM Pro (192.168.0.1)
- **Management Network**: 192.168.0.0/24 (UniFi management interface)
- **Kubernetes Network**: 192.168.20.0/24 (nodes and services)
  - Node IPs: 192.168.20.51-53
  - VIP: 192.168.20.60
  - MinIO: 192.168.20.5:9000
- **DNS**: Pi-hole on Raspberry Pi (192.168.20.1)
- **VLANs**: Configured via Terraform in `infrastructure/terraform/unifi/vlans.tf`

## Storage

- **Longhorn**: Distributed block storage using nvme and ssd volumes on each node
  - Each node has two disk configurations: nvme (`/var/lib/longhorn`) and ssd (`/var/mnt/ssd/longhorn`)
  - Tagged with `nvme` and `ssd` respectively for scheduling constraints
- **Kopiur**: PVC backup/restore via Kopia to a shared repository on Garage S3 (see Kopiur Operations)
- **Garage**: S3-compatible object storage for backups and app buckets (`192.168.20.5:3900`)
- **MinIO**: S3-compatible object storage on NAS (Synology RS422+); hosts Terraform state and the
  legacy VolSync restic cold-archive buckets

## Important Notes

- **Talos Configuration**: Generated via talhelper from `kubernetes/bootstrap/talos/talconfig.yaml`
  - Do not manually edit files in `clusterconfig/` directory - they are generated
  - Make changes in `talconfig.yaml` and regenerate with `task talos:generate-config`
- **Renovate**: Automated dependency updates via Renovate bot
  - Updates Docker images, Helm charts, and Terraform providers
  - PRs are automatically created for review
- **Kubeconfig**: Generated in repository root as `kubeconfig` (gitignored)
- **SOPS Age Key**: Must be present in repository root as `age.key` (gitignored)
- **1Password Connect**: Required for Terraform operations and Kubernetes External Secrets
  - Start temporary server: `docker-compose -f infrastructure/1password-store/docker-compose.yaml up -d`
  - Credentials file: `infrastructure/1password-store/1password-credentials.json` (gitignored)
