# Clone recipes

Template VM IDs produced by `build.sh`:

| OS | vmid | Template name |
|----|------|---------------|
| Windows Server 2022 Desktop | 9022 | `win2022-desktop-tpl` |
| Windows Server 2025 Desktop | 9025 | `win2025-desktop-tpl` |

## Minimal clone (static IP)

```bash
NEWID=210
qm clone 9025 $NEWID --name win2025-app01 --full
qm set $NEWID \
    --ciuser Administrator \
    --cipassword 'S3cure!Pass' \
    --ipconfig0 'ip=10.0.0.50/24,gw=10.0.0.1' \
    --nameserver 10.0.0.1 \
    --searchdomain lan
qm cloudinit update $NEWID
qm start $NEWID
```

First boot runs sysprep specialize + OOBE; Cloudbase-Init applies hostname (= `--name`), Administrator password, and NIC settings within ~2–3 minutes.

## DHCP

```bash
qm set $NEWID --ipconfig0 'ip=dhcp'
```

## Bulk clone via Terraform (sketch)

```hcl
resource "proxmox_vm_qemu" "win" {
  name        = "win2025-app01"
  target_node = "pve01"
  clone       = "win2025-desktop-tpl"
  full_clone  = true
  os_type     = "cloud-init"
  ciuser      = "Administrator"
  cipassword  = var.admin_password
  ipconfig0   = "ip=10.0.0.50/24,gw=10.0.0.1"
  nameserver  = "10.0.0.1"
}
```

## Troubleshooting

- **Admin password not accepted** — Proxmox hashes `cipassword` for `ostype=win*`. If Cloudbase-Init can't decrypt, use `cicustom` with a `user-data` snippet that carries the plaintext password (see RESEARCH.md §Known pain points).
- **Cloud-init CDROM not visible** — Template must be `q35` + `x86-64-v2-AES`. Check `qm config <id> | grep -E 'machine|cpu'`.
- **Hostname not set / network missing** — SSH/RDP to the VM, inspect `C:\Program Files\Cloudbase Solutions\Cloudbase-Init\log\cloudbase-init.log`.
- **Clone stuck "Starting Windows"** — VirtIO storage/net drivers missing or stale. Rebuild template with newer virtio-win ISO (≥ 0.1.240).
- **Second clone from same template works differently** — Confirm `qm cloudinit update` was run after `qm set` each time.

## Verification checklist per clone

1. `ping <clone-ip>` responds.
2. RDP as `Administrator` with the password set via `--cipassword`.
3. `Get-ComputerInfo | Select CsName` on the VM returns the clone name.
4. `Get-Content 'C:\Program Files\Cloudbase Solutions\Cloudbase-Init\log\cloudbase-init.log' | Select-String 'Plugins execution completed'` shows success.
