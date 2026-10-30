# Setup Guide

## Install and Configure Proxmox

1. Download the official image from
   the [Proxmox site](https://www.proxmox.com/en/downloads/proxmox-virtual-environment/iso).
2. Flash the image and install it on the machines. During installation, specify and write down the static IP address
   that will be used by the machine.
3. Go to the machine disks, click on an SSD, and select "Initialize disk with GPT."
4. Go to the LVM subsection and add a new Volume Group based on the disk, named "SSD."
5. Inspect the [Ansible inventory file](../infrastructure/ansible/inventory/hosts.yaml) and
   run `task ansible:proxmox-setup` to configure Proxmox nodes. This will provision the SSH key, update Proxmox to the
   latest versions, and set up GPU passthrough. For any troubleshooting with GPU, check
   out [this guide](https://3os.org/infrastructure/proxmox/gpu-passthrough/igpu-passthrough-to-vm/#proxmox-configuration-for-igpu-full-passthrough).
6. Go to Network, select Linux Bridge, and check the `VLAN aware` checkbox to assign virtual machines to different
   VLANs.
7. Set up a simple Proxmox cluster using the menu wizard. No need to make it HA since Kubernetes will handle the HA.

## Create and Install Talos Images

1. Head over to [Talos Factory](https://factory.talos.dev) and follow the instructions to download a Talos Linux ISO
   file. Note the schematic ID; you will need this later on. Add the following extensions:

- siderolabs/iscsi-tools -- for Longhorn
- siderolabs/util-linux-tools -- for Longhorn
- siderolabs/qemu-guest-agent -- for managing VMs from the Proxmox UI
- siderolabs/i915 -- for GPU support
- siderolabs/gvisor -- for the gVisor (runsc) sandboxed pod runtime; requires Cilium `datapathMode: veth`

2. Go to `/infrastructure/terraform/proxmox/talos.tofu` and update the ISO URL if needed.
3. Check the Terraform changes with `terraform plan`.
4. Run Terraform to create VMs with Talos nodes:
   ```sh
   terraform apply
   ```

## Bootstrap kubernetes cluster

1. Deploy the Talos cluster to machines:
   ```sh
   task bootstrap:talos
   ```
   It might take a while for the cluster to be set up (10+ minutes is normal), during which time you will see various
   error messages like: “couldn’t get current server API group list,” “error: no matching resources found,” etc. This is
   normal. If this step gets interrupted, e.g., by pressing Ctrl + C, you likely will need to nuke the cluster before
   trying again.

   This task will create a talosconfig in the /kubernetes/bootstrap/talos/clusterconfig directory. You can use it to get
   access to a Talos cluster for troubleshooting:
   ```sh
   talosctl --talosconfig=./kubernetes/bootstrap/talos/clusterconfig/talosconfig --nodes=192.168.20.51 health
   ```

2. The `kubeconfig` for interacting with the cluster will be generated in the root directory. Verify the nodes are online:
    ```sh
    kubectl get nodes -o wide
    # NAME            STATUS   ROLES           AGE     VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE         KERNEL-VERSION   CONTAINER-RUNTIME
    # k8s-control-1   Ready    control-plane   4d21h   v1.30.1   192.168.20.51   <none>        Talos (v1.7.2)   6.6.30-talos     containerd://1.7.16
    # k8s-control-2   Ready    control-plane   4d22h   v1.30.1   192.168.20.52   <none>        Talos (v1.7.2)   6.6.30-talos     containerd://1.7.16
    # k8s-control-3   Ready    control-plane   4d21h   v1.30.1   192.168.20.53   <none>        Talos (v1.7.2)   6.6.30-talos     containerd://1.7.16
    ```

3. Continue with installing apps
    ```sh
   task bootstrap:apps
   ```

## Post-bootstrap manual steps

### CrowdSec console enrollment (optional)

CrowdSec is fully protective from Git on its own (bouncer, collections, Envoy log parsing, community
blocklist, ext-authz on `envoy-external`). Enrolling in the hosted console at app.crowdsec.net is
optional (web dashboard + extra blocklists) and must be done by hand, once per cluster:

1. Ensure the 1Password `crowdsec` item has `CROWDSEC_BOUNCER_KEY` (random 64-char) and
   `CROWDSEC_ENROLL_KEY` (from app.crowdsec.net).
2. `kubectl -n network exec deploy/crowdsec-lapi -- sh -c 'cscli console enroll "$ENROLL_KEY"'`
3. Accept the instance at **app.crowdsec.net → Security Engines**.
