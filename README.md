<div align="center">

<img src="https://raw.githubusercontent.com/kubepug/kubepug/main/assets/kubepug.png" align="center" width="250px" />

## My Homelab playground
_... the way of a front-end developer cosplaying a sysadmin_ 🗿

</div>

<div align="center">

[![Age-Days](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.exelent.click%2Fcluster_age_days&style=flat-square&label=Age)](https://github.com/kashalls/kromgo/)&nbsp;&nbsp;
[![Uptime-Days](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.exelent.click%2Fcluster_uptime_days&style=flat-square&label=Uptime)](https://github.com/kashalls/kromgo/)&nbsp;&nbsp;
[![Node-Count](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.exelent.click%2Fcluster_node_count&style=flat-square&label=Nodes)](https://github.com/kashalls/kromgo/)&nbsp;&nbsp;
[![Pod-Count](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.exelent.click%2Fcluster_pod_count&style=flat-square&label=Pods)](https://github.com/kashalls/kromgo/)&nbsp;&nbsp;
[![CPU-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.exelent.click%2Fcluster_cpu_usage&style=flat-square&label=CPU)](https://github.com/kashalls/kromgo/)&nbsp;&nbsp;
[![Memory-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.exelent.click%2Fcluster_memory_usage&style=flat-square&label=Memory)](https://github.com/kashalls/kromgo/)&nbsp;&nbsp;

</div>

---

## 🍼 Overview

👋 Welcome to my Kubernetes Homelab Cluster repository! This project serves as a practical learning environment for
exploring Kubernetes and Infrastructure as Code (IaC) practices using tools like  [FluxCD](https://fluxcd.io),
[Renovate](https://github.com/renovatebot/renovate), [go-task](https://github.com/go-task/task) and other

## 📖 Table of contents

- [🍼 Overview](#-overview)
- [📖 Table of contents](#-table-of-contents)
- [📚 Documentation](#-documentation)
- [🖥️ Technological Stack](#-technological-stack)
- [🔧 Hardware](#-hardware)
- [☁️ External Dependencies](#-external-dependencies)
- [🤖 Automation](#-automation)
- [🤝 Thanks](#-thanks)

## 📚 Documentation

1. [Prerequisites](docs/prerequisites.md)
   - [Cloudflare](docs/prerequisites.md#1-set-up-cloudflare)
   - [Secrets store](docs/prerequisites.md#2-set-up-secrets-store)
   - [UDM](docs/prerequisites.md#3-set-up-udm)
   - [Discord](docs/prerequisites.md#4-get-discord-token)
   - [PiHole](docs/prerequisites.md#5-set-up-pihole-and-generate-token-for-homepage)
   - [NAS and Minio](docs/prerequisites.md#6-nas-set-up)
2. [Setup Guide](docs/set-up.md)
   - [Install and Configure Proxmox](docs/set-up.md#install-and-configure-proxmox)
   - [Create and Install Talos Images](docs/set-up.md#create-and-install-talos-images)
   - [Bootstrap Kubernetes Cluster](docs/set-up.md#bootstrap-kubernetes-cluster)
   - [Install Flux](docs/set-up.md#install-flux)
3. [How To](docs/howto.md)

## 🖥️ Technological Stack

|                                                                                                                                | Name                                                                        | Description                                                                                            |
|--------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------|
| <img width="32" src="https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/svg/proxmox.svg">                        | [Proxmox](https://www.proxmox.com)                                          | Virtualization platform                                                                                |
| <img width="32" src="https://github.com/cncf/artwork/raw/main/projects/kubernetes/icon/color/kubernetes-icon-color.svg">       | [Kubernetes](https://kubernetes.io/)                                        | An open-source system for automating deployment, scaling, and management of containerized applications |
| <img width="32" src="https://github.com/cncf/artwork/raw/main/projects/helm/icon/color/helm-icon-color.svg">                   | [Helm](https://helm.sh)                                                     | The Kubernetes package manager                                                                         |
| <img width="32" src="https://github.com/cncf/artwork/raw/main/projects/flux/icon/color/flux-icon-color.svg">                   | [FluxCD](https://fluxcd.io/)                                                | GitOps tool for deploying applications to Kubernetes                                                   |
| <img width="32" src="https://www.talos.dev/images/logo.svg">                                                                   | [Talos Linux](https://www.talos.dev/)                                       | Talos Linux is Linux designed for Kubernetes                                                           |
| <img width="32" src="https://github.com/cncf/artwork/raw/main/projects/cert-manager/icon/color/cert-manager-icon-color.svg">   | [Cert Manager](https://cert-manager.io/)                                    | X.509 certificate management for Kubernetes                                                            |
| <img width="32" src="https://github.com/cncf/artwork/raw/main/projects/cilium/icon/color/cilium_icon-color.svg">               | [Cilium](https://cilium.io/)                                                | Internal Kubernetes container networking interface.                                                    |
| <img width="32" src="https://docs.nginx.com/nginx-ingress-controller/images/icons/NGINX-Ingress-Controller-product-icon.svg">  | [Ingress-nginx](https://github.com/kubernetes/ingress-nginx)                | Kubernetes ingress controller using NGINX as a reverse proxy and load balancer.                        |
| <img width="32" src="https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/svg/cloudflare.svg">                     | [Cloudflared](https://github.com/cloudflare/cloudflared)                    | Enables Cloudflare secure access to certain ingresses.                                                 |
| <img width="32" src="https://github.com/cncf/artwork/raw/main/projects/coredns/icon/color/coredns-icon-color.svg">             | [CoreDNS](https://coredns.io/)                                              | Cluster DNS server                                                                                     |
| <img width="32" src="https://raw.githubusercontent.com/kubernetes/community/master/icons/png/resources/unlabeled/pod-128.png"> | [Spegel](https://github.com/spegel-org/spegel)                              | Stateless cluster local OCI registry mirror.                                                           |
| <img width="32" src="https://raw.githubusercontent.com/kubernetes-sigs/external-dns/master/docs/img/external-dns.png">         | [External-dns](https://github.com/kubernetes-sigs/external-dns/tree/master) | Automatically syncs ingress DNS records to a DNS provider.                                             |
| <img width="32" src="https://raw.githubusercontent.com/external-secrets/external-secrets/main/assets/eso-logo-large.png">      | [External Secrets](https://github.com/external-secrets/external-secrets)    | Managed Kubernetes secrets using [1Password Connect](https://github.com/1Password/connect).            |
| <img width="32" src="https://avatars.githubusercontent.com/u/129185620">                                                       | [Sops](https://github.com/getsops/sops)                                     | Managed secrets for Kubernetes and which are commited to Git.                                          |
| <img width="32" src="https://raw.githubusercontent.com/walkxcode/dashboard-icons/main/svg/longhorn.svg">                       | [Longhorn](https://longhorn.io)                                             | Cloud native distributed block storage for Kubernetes                                                  |
| <img width="32" src="https://avatars.githubusercontent.com/u/47803932">                                                        | [VolSync](https://github.com/backube/volsync)                               | Backup and recovery of persistent volume claims.                                                       |
| <img width="32" src="https://github.com/cncf/artwork/raw/main/projects/prometheus/icon/color/prometheus-icon-color.svg">       | [Prometheus](https://prometheus.io)                                         | Monitoring system and time series database                                                             |
| <img width="32" src="https://github.com/cncf/artwork/raw/main/projects/thanos/icon/color/thanos-icon-color.svg">               | [Thanos](https://thanos.io)                                                 | Highly available Prometheus setup with long-term storage capabilities                                  |
| <img width="32" src="https://grafana.com/static/img/menu/grafana2.svg">                                                        | [Grafana](https://grafana.com)                                              | Data and logs visualization                                                                            |
| <img width="32" src="https://github.com/grafana/loki/blob/main/docs/sources/logo.png?raw=true">                                | [Loki](https://grafana.com/oss/loki/)                                       | Horizontally-scalable, highly-available, multi-tenant log aggregation system                           |
| <img width="32" src="https://avatars.githubusercontent.com/u/16866914">                                                        | [Vector](https://github.com/vectordotdev/vector)                            | Collects, transform and routes logs to Loki                                                            |


## 🔧 Hardware

<details>
  <summary>Rack photo</summary>

  <img src="https://raw.githubusercontent.com/MaksimShakavin/flux-homelab/main/docs/assets/rack.jpg" align="center" width="200px" alt="rack"/>
</details>

| Device                     | Count | Disk Size  | RAM  | OS      | Purpose                 |
|----------------------------|-------|------------|------|---------|-------------------------|
| Lenovo M910Q Tiny i5-6500T | 3     | 2x1TB SSD  | 32GB | Talos   | Kubernetes Master Nodes |
| Raspberry Pi 5             | 1     |            | 8GB  | RpiOS   | DNS, SmartHome          |
| Synology RS422+            | 1     | 4x16TB HDD | 2GB  | DSM     | NAS                     |
| UPS 5UTRA91227             | 1     |            |      |         | UPS                     |
| UniFi UDM Pro              | 1     |            |      | UnifiOS | Router                  |
| UniFi USW PRO 24 Gen2      | 1     |            |      |         | Switch                  |
| UniFi USW Lite 8           | 1     |            |      |         | Switch                  |
| UniFi U6 In-Wall           | 1     |            |      |         | Access Point            |
| UniFi U6 Mesh              | 1     |            |      |         | Access Point            |

## ☁️ External Dependencies

This list does not include cloud services that I use for personal reasons and don't yet want to migrate to self-hosted,
such as Google (Gmail, Photos, Drive), streaming services, Apple, and some applications. Legacy cloud services listed
at the bottom are remnants from previous attempts to set up smart home observability dashboards and will be migrated
and shut down ~~never~~ as soon as I have time to transfer all the configurations.

| Service                                   | Description                                                                  | Costs            |
|-------------------------------------------|------------------------------------------------------------------------------|------------------|
| [1Password](https://1password.com)        | Secrets managements                                                          | 76$/year         |
| [Cloudflare](https://www.cloudflare.com/) | Domain and DNS                                                               | Free             |
| [GitHub](https://github.com/)             | Repository Hosting                                                           | Free             |
| [Discord](https://discord.com)            | Notifications                                                                | Free             |
| [Let's Encrypt](https://discord.com)      | Certificates                                                                 | Free             |
| [Notifiarr](https://notifiarr.com)        | Notifications push                                                           | 5$ one time      |
| [AWS Route 53](https://aws.amazon.com/)   | Domain                                                                       | 0,5$/month       |
| [AWS EC2 ](https://aws.amazon.com/)       | (Legacy) Grafana, InfluxDB hosting for smart home analytics. Need to migrate | ~15$/month       |
| [InfluxDB Cloud](https://aws.amazon.com/) | (Legacy) Smart home data storage. Need to migrate                            | ~14$/month       |
| [AWS Other ](https://aws.amazon.com/)     | (Legacy) Email hosting. Need to migrate                                      | ~10$/month       |
|                                           |                                                                              | Total: 45$/month |



## 🤝 Thanks

This project was mostly ~~copypasted from~~ inspired by a [onedr0p/home-ops](https://github.com/onedr0p/home-ops)
and [onedr0p/cluster-template](https://github.com/onedr0p/cluster-template) repositories.
A big thanks to the members of the [Home Operations](https://discord.gg/home-operations) community
for their support and for sharing their repositories.
Additional thanks to the [Kubesearch](https://kubesearch.dev/) project for ability to search for different configurations.
Thanks [kubepug](https://github.com/kubepug) for the logo. I like pugs
