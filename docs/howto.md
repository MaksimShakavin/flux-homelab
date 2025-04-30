## How to

### Reset node ephemeral storage

In case some of the local hostpath PVs use all the node storage and fill up the disk, the only way is to completely
reset the disk. It can be done with the following command:

```sh
talosctl --talosconfig=./kubernetes/bootstrap/talos/clusterconfig/talosconfig --nodes=[NODE_IP] reset --system-labels-to-wipe EPHEMERAL
 ```

1. Start the node from the Proxmox UI.
2. Manually delete all previous PVCs and PVs for a local-hostpath storage class that were hosted on the node.
3. Manually delete pods so they are recreated

### Upgrade ssd storage

1. Add a new SSD to the machine
2. Wipe it from the Proxmox UI and press “Initialize Disk with GPT.”
3. Create a new LVM Volume group. LVM allows creating snapshots, which is probably not needed.
4. Add the disk as hardware to the VM. Don’t forget to disable backup.

### Replace a node

1. Reset the Talos node
   ```sh
   talosctl --talosconfig=./kubernetes/bootstrap/talos/clusterconfig/talosconfig --nodes=[node-ip] reset`
   ```
2. Delete the node from Kubernetes
   ```shell
   kubectl delete node <nodename>
   ```
3. Delete the node from the Proxmox cluster. SSH to an existing node and run:
   ```sh
   pvecm delnode [node-name]
   ```
   where node-name is the name from the Proxmox cluster configuration.
4. Delete information about the node on Proxmox machines from /etc/pve/nodes.
5. Continue with the [setup guide](./set-up.md) until the bootstrapping cluster point.
6. Apply the configuration to the new node:
   ```sh
   talosctl apply-config --talosconfig=./clusterconfig/talosconfig --nodes=[node-ip] --file=./clusterconfig/home-kubernetes-k8s-control-1.yaml --insecure`
   ```

### Remove Cluster Info from Proxmox Node

```sh
systemctl stop pve-cluster corosync
pmxcfs -l
rm -rf /etc/corosync/*
rm /etc/pve/corosync.conf
killall pmxcfs
systemctl start pve-cluster
```

Delete information about rest nodes in /etc/pve/nodes

### Set Up GitHub App for a New Repository

1. Create a GitHub app following
   the [guideline](https://docs.github.com/en/apps/creating-github-apps/registering-a-github-app/registering-a-github-app)
2. Copy the app ID and save it to a `BOT_APP_ID` repository secret and to a `ACTION_RUNNER_CONTROLLER_GITHUB_APP_ID`
   property of an `actions-runner-controller` 1Password secret.
3. Generate a new app private key and add it to a `BOT_APP_PRIVATE_KEY` repository secret and to
   the `ACTION_RUNNER_CONTROLLER_GITHUB_PRIVATE_KEY` property of an `actions-runner-controller` 1Password secret in the
   format
   ```
   -----BEGIN RSA PRIVATE KEY-----
   ...
   -----END RSA PRIVATE KEY-----
   ```

### Update talos image on a node

1. Generate talosctl command
    ```shell
    talhelper gencommand upgrade --node 192.168.20.52 --extra-flags "--timeout=10m"
    ```
2. Copy-paste and execute result command
    ```shell
    talosctl upgrade --talosconfig=./clusterconfig/talosconfig --nodes=192.168.20.52 --image=factory.talos.dev/installer/583560d413df7502f15f3c274c36fc23ce1af48cef89e98b1e563fb49127606e:v1.9.5 --timeout=10m;

    ```

### Remove minio bucket

1. Authenticate to minio
    ```shell
    mc alias set myminio http://192.168.20.5:9000 [USER] [PASSWORD]
    ```
2. Remove the bucket
    ```shell
    mc rb --force --dangerous myminio/mybucket
    ```


