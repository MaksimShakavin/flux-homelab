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
3. Edit `/etc/default/grub` with the following changes:
  ```
  GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on"
  ```
4. Run `update-grub` and reboot the node
5. Verify that IOMMU is enabled
```
dmesg | grep -e DMAR -e IOMMU
```
There should be a line that looks like `DMAR: IOMMU enabled`
6. For any troubleshouting check out [this guide](https://3os.org/infrastructure/proxmox/gpu-passthrough/igpu-passthrough-to-vm/#proxmox-configuration-for-igpu-full-passthrough)

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

## Bootstrap kubernetes claster
```
task talos:bootstrap
```
