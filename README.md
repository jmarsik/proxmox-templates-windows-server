# Lekis-ProxmoxTemplates

Packer automation that builds cloud-init-ready **Windows Server 2022 Desktop** and **Windows Server 2025 Desktop** golden templates on **Proxmox VE 9** using **Cloudbase-Init**.

Clones get hostname, Administrator password, and network config from Proxmox's cloud-init drive via `qm set --ciuser/--cipassword/--ipconfig0`.

## Prerequisites

- Proxmox VE 9 host with API reachable.
- Proxmox API token for an automation user (`packer@pve!packer`) with these role privileges: `Datastore.AllocateSpace`, `Datastore.Audit`, `VM.Allocate`, `VM.Audit`, `VM.Clone`, `VM.Config.*`, `VM.Monitor`, `VM.PowerMgmt`, `Pool.Allocate`, `SDN.Use`, `Sys.Audit`, `Sys.Modify`.
- Uploaded to an ISO datastore:
  - Windows Server 2022 ISO (eval or licensed).
  - Windows Server 2025 ISO.
  - VirtIO drivers ISO ≥ `virtio-win-0.1.240`.
- Local machine with [pixi](https://pixi.sh) installed.
- `q35` machine type + `x86-64-v2-AES` CPU required or Windows won't see the cloud-init CDROM (hardcoded in `sources.pkr.hcl`).

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
qm set 210 --ciuser Administrator --cipassword 'S3cure!Pass'
qm set 210 --ipconfig0 'ip=10.0.0.50/24,gw=10.0.0.1' --nameserver 10.0.0.1
qm cloudinit update 210
qm start 210
```

Cloudbase-Init applies settings ~2–3 min after first boot. Detail in `docs/clone-examples.md`.

## Repo layout

See `PLAN-2026-04-18-packer-windows-proxmox-templates.md` for full architecture + `RESEARCH.md` for background on Proxmox 9 + Cloudbase-Init gotchas.

## Pixi tasks

| Task | Purpose |
|------|---------|
| `pixi run init` | `packer init .` — install plugins |
| `pixi run fmt` | `packer fmt -recursive .` |
| `pixi run validate-2025` | Validate HCL against `pkrvars/2025-desktop.pkrvars.hcl` |
| `pixi run validate-2022` | Same for 2022 |
| `pixi run build-2025` | Full build via `build.sh 2025-desktop` |
| `pixi run build-2022` | Full build via `build.sh 2022-desktop` |
