# Lekis-ProxmoxTemplates

Packer automation that builds cloud-init-ready **Windows Server 2022 Desktop** and **Windows Server 2025 Desktop** golden templates on **Proxmox VE 9** using **Cloudbase-Init**.

Clones get hostname, Administrator password and SSH public key, network config and Windows Update setting from Proxmox's cloud-init drive via `qm set --cipassword/--sshkeys/--ipconfig0/--nameserver/--searchdomain/--ciupgrade`.

Setting username via cloud-init (`--ciuser`) doesn't work out of the box, because Cloudbase-Init expects it in a different place than Proxmox puts it.

## Prerequisites

- Proxmox VE 9 host with API reachable.
- Proxmox API token for an automation user (`packer@pve!packer`) with sufficient permissions.
- Uploaded to an ISO datastore:
  - Windows Server 2022 ISO (eval or licensed).
  - Windows Server 2025 ISO.
  - VirtIO drivers ISO ≥ `virtio-win-0.1.240`.
- Local machine with [pixi](https://pixi.sh) installed.

## Quick start

```bash
pixi install

# first time per variant
cp pkrvars/2025-desktop.pkrvars.hcl.example pkrvars/2025-desktop.pkrvars.hcl
$EDITOR pkrvars/2025-desktop.pkrvars.hcl          # set proxmox_url, node, storage, ISOs

export PKR_VAR_proxmox_api_token='<token-secret>'

./build.sh 2025-desktop                            # or: pixi run build-2025
./build.sh 2022-desktop                            # or: pixi run build-2022
```

Build produces a Proxmox template with `vmid=9025` (or `9022`) named per `vm_name`.

## Clone flow

```bash
qm clone 9025 210 --name win2025-app01 --full
qm set 210 --cipassword 'S3cure!Pass'
qm set 210 --ipconfig0 'ip=10.0.0.50/24,gw=10.0.0.1' --nameserver 10.0.0.1
qm cloudinit update 210
qm start 210
```

Cloudbase-Init applies settings ~2–3 min after first boot.

**It's important to remove the `CloudInit Drive` hardware component (via UI or `qm`) after the first boot, otherwise it can cause issues with subsequent boots (re-applying some settings).**

## Cloud-init resources

- [Cloudbase-Init documentation](https://cloudbase.github.io/cloudbase-init/)
- [Proxmox Cloud-Init Support](https://pve.proxmox.com/wiki/Cloud-Init_Support)
- [Proxmox Cloud-Init FAQ](https://pve.proxmox.com/wiki/Cloud-Init_FAQ)
- [Proxmox Cloud-Init Made Easy: Automating VM Provisioning Like the Cloud](https://www.virtualizationhowto.com/2025/10/proxmox-cloud-init-made-easy-automating-vm-provisioning-like-the-cloud/)
- [GitLab pve-cloud-init-creator](https://gitlab.com/morph027/pve-cloud-init-creator)
