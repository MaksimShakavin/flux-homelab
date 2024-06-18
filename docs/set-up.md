# Set up guide

## Install and configure Proxmox

1. Download official image from an official Proxmox [site](https://www.proxmox.com/en/downloads/proxmox-virtual-environment/iso)
2. Flush image and install it to the machines. During installation specify and write down static ip address that will be
used by the machine.
3. Disable subscription repositories. Go to Repositories setting menu and disable all components marked as `enterprise` and
`pve-enterprise`
4. ssh to the node and run `apt get update` following by `apt get upgrade`
5. Go to Network, select Linux Bridge and check `VLAN aware checkox` in order to be able to assign virtual machines to a
different VLANs.
6. Set up a simple proxmox cluster using menu wizard. No need to make it HA since kubernetes will handle the HA.

### Set up GPU passthrough
1. Edit `/etc/default/grub` with the following changes:
  ```
  GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on"
  ```
2. Run `update-grub` and reboot the node
3. Verify that IOMMU is enabled
```
dmesg | grep -e DMAR -e IOMMU
```
There should be a line that looks like `DMAR: IOMMU enabled`
4. For any troubleshouting check out [this guide](https://3os.org/infrastructure/proxmox/gpu-passthrough/igpu-passthrough-to-vm/#proxmox-configuration-for-igpu-full-passthrough)

## Create and install Talos images
1. Head over to https://factory.talos.dev and follow the instructions which will eventually lead you to download a Talos
Linux iso file. Make sure to note the schematic ID you will need this later on. Add following extensions
   - siderolabs/iscsi-tools -- for longhorn
   - siderolabs/util-linux-tools -- for longhorn
   - siderolabs/qemu-guest-agent -- for being able to manage VM from a proxmox UI
2. Create VM with following configuration:
  - Startup on boot
  - Bios: SeaBios
  - Machine: q35
  - Memory: baloon disabled
  - CPU: type host, cpu units 1024
  - Network: vlan 20, firewall disabled, mac address one of the following: BC:24:11:B5:DD:1F, BC:24:11:0C:FD:22, BC:24:11:A8:19:33
3. Add PCI device `Inter HD Graphics`

## Bootstrap kubernetes cluster
1. Deploy the talos cluster to machines
```
task talos:bootstrap
```

2. It might take a while for the cluster to be setup (10+ minutes is normal), during which time you will see a variety of
error messages like: "couldn't get current server API group list," "error: no matching resources found", etc. This is a
normal. If this step gets interrupted, e.g. by pressing Ctrl + C, you likely will need to nuke the cluster
before trying again.

This task will create a `talosconfig` in a `/kubernetes/bootstrap/talos/clusterconfig` directory. You can use it to
get access to a Talos cluster for troubleshooting
```
talosctl --talosconfig=./kubernetes/bootstrap/talos/clusterconfig/talosconfig --nodes=192.168.20.51 health
```

3. The `kubeconfig` for interacting with the cluster will be generated in the root directory.

    Verify the nodes are online:
    ```shell
    kubectl get nodes -o wide
    # NAME            STATUS   ROLES           AGE     VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE         KERNEL-VERSION   CONTAINER-RUNTIME
    # k8s-control-1   Ready    control-plane   4d21h   v1.30.1   192.168.20.51   <none>        Talos (v1.7.2)   6.6.30-talos     containerd://1.7.16
    # k8s-control-2   Ready    control-plane   4d22h   v1.30.1   192.168.20.52   <none>        Talos (v1.7.2)   6.6.30-talos     containerd://1.7.16
    # k8s-control-3   Ready    control-plane   4d21h   v1.30.1   192.168.20.53   <none>        Talos (v1.7.2)   6.6.30-talos     containerd://1.7.16
    ```

4. Continue with installing flux

## Install Flux

1. Verify Flux can be installed

    ```sh
    flux check --pre
    # ► checking prerequisites
    # ✔ kubectl 1.30.1 >=1.18.0-0
    # ✔ Kubernetes 1.30.1 >=1.16.0-0
    # ✔ prerequisites checks passed
    ```

2. Install Flux and sync the cluster to the Git repository

   📍 _Run `task flux:github-deploy-key` first if using a private repository._

    ```sh
    task flux:bootstrap
    # namespace/flux-system configured
    # customresourcedefinition.apiextensions.k8s.io/alerts.notification.toolkit.fluxcd.io created
    # ...
    ```

3. Verify Flux components are running in the cluster

    ```sh
    kubectl -n flux-system get pods -o wide
    # NAME                                       READY   STATUS    RESTARTS   AGE
    # helm-controller-5bbd94c75-89sb4            1/1     Running   0          1h
    # kustomize-controller-7b67b6b77d-nqc67      1/1     Running   0          1h
    # notification-controller-7c46575844-k4bvr   1/1     Running   0          1h
    # source-controller-7d6875bcb4-zqw9f         1/1     Running   0          1h
    ```
