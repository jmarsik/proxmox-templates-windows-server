# Proxmox 9 + Windows 2022/2025 + Packer + Cloudbase-Init — Research Summary

## Core architecture

Windows no cloud-init native. Flow:
1. **Packer** build golden image via ISO + Autounattend.xml + VirtIO drivers.
2. Install **Cloudbase-Init** inside image, configure for Proxmox's config drive.
3. **Sysprep /generalize /oobe /shutdown**, convert VM → template.
4. **Clone** template, set `qm set` cloud-init args → Proxmox generates config-drive ISO → Cloudbase-Init reads on first boot → sets hostname/admin password/network.

## Key Proxmox 9 gotchas

- **Machine type must be `q35` + CPU `x86-64-v2-AES`** (not `pc`/`host`) or Windows won't see the cloud-init CDROM. Confirmed Packer+Cloudbase-Init failure mode on Proxmox forum.
- Proxmox picks **ConfigDrive2** when `ostype=win*`; but several working tutorials use **NoCloud** variant with matching Cloudbase-Init service — pick one and align.
- Password injection: Proxmox stores `cipassword` hashed by default. Cloudbase-Init cannot decrypt. Options:
  - Patch `/usr/share/perl5/PVE/API2/Qemu.pm` + `Cloudinit.pm` to pass plaintext (community hack).
  - Or set `inject_user_password=true` in Cloudbase-Init; recent Proxmox versions pass usable password via config drive for Windows path.
- Sysprep + Cloudbase-Init install order: install Cloudbase-Init, choose "Run Sysprep" checkbox at end, do **not** reboot.

## Cloudbase-Init config (both `cloudbase-init.conf` + `cloudbase-init-unattend.conf`)

```ini
[DEFAULT]
username=Administrator
groups=Administrators
inject_user_password=true
first_logon_behaviour=no
config_drive_raw_hhd=true
config_drive_cdrom=true
config_drive_vfat=true
bsdtar_path=C:\Program Files\Cloudbase Solutions\Cloudbase-Init\bin\bsdtar.exe
mtools_path=C:\Program Files\Cloudbase Solutions\Cloudbase-Init\bin\
verbose=true
logdir=C:\Program Files\Cloudbase Solutions\Cloudbase-Init\log\
logfile=cloudbase-init.log
default_log_levels=comtypes=INFO,suds=INFO,iso8601=WARN,requests=WARN
logging_serial_port_settings=
mtu_use_dhcp_config=true
ntp_use_dhcp_config=true
local_scripts_path=C:\Program Files\Cloudbase Solutions\Cloudbase-Init\LocalScripts\
metadata_services=cloudbaseinit.metadata.services.configdrive.ConfigDriveService,cloudbaseinit.metadata.services.nocloudservice.NoCloudConfigDriveService
plugins=cloudbaseinit.plugins.common.mtu.MTUPlugin,
    cloudbaseinit.plugins.windows.ntpclient.NTPClientPlugin,
    cloudbaseinit.plugins.common.sethostname.SetHostNamePlugin,
    cloudbaseinit.plugins.windows.extendvolumes.ExtendVolumesPlugin,
    cloudbaseinit.plugins.common.userdata.UserDataPlugin,
    cloudbaseinit.plugins.common.setuserpassword.SetUserPasswordPlugin,
    cloudbaseinit.plugins.windows.createuser.CreateUserPlugin,
    cloudbaseinit.plugins.common.networkconfig.NetworkConfigPlugin
allow_reboot=false
stop_service_on_exit=false
check_latest_version=false
rename_admin_user=false
```

Dual `metadata_services` lets it work with either NoCloud or ConfigDrive2 drive that Proxmox generates.

## Packer layout (proven, from mfgjwaterman)

```
proxmox-windows-server-2025-desktop/
├── variables.pkr.hcl
├── windows-server-2025-desktop.pkr.hcl      # source proxmox-iso
└── scripts/
    ├── pre-build/
    │   ├── Autounattend.xml                 # packed to cd_files ISO
    │   ├── $WinpeDriver$/                   # virtio storage+NIC for WinPE
    │   └── build/                           # first-logon install scripts
    └── post-build/
        ├── install-cloudbase-init.ps1
        ├── cloudbase-init.conf              # uploaded post-install
        ├── cloudbase-init-unattend.conf
        ├── cleanup-for-image.ps1
        ├── setupcomplete/SetupComplete.cmd
        └── unattend/sysprep-unattend.xml    # sysprep generalize answer file
```

Packer builder pattern: `proxmox-iso` plugin v1.2.2+, `windows-update` plugin v0.14.0+. Boot dynamic ISO (cd_files) carrying Autounattend + VirtIO WinPE drivers. WinRM over TLS self-signed. Uses temp password `P@ssw0rd!` for build only — reset at sysprep.

Source block essentials:
```hcl
machine              = "q35"
bios                 = "ovmf"
cpu_type             = "x86-64-v2-AES"
scsi_controller      = "virtio-scsi-single"
network_adapters { model = "virtio", bridge = "vmbr0" }
disks { type = "virtio", disk_size = "80G", storage_pool = var.proxmox_storage_pool, format = "raw" }
iso_file             = var.vm_boot_iso
additional_iso_files {
  cd_files = ["./scripts/pre-build/Autounattend.xml", "./scripts/pre-build/$WinpeDriver$/*", "./scripts/pre-build/build/*"]
  iso_storage_pool = var.proxmox_iso_storage_pool
  unmount = true
}
additional_iso_files { device = "ide3", iso_file = var.vm_virtio_iso }
communicator = "winrm"
winrm_use_ssl = true
winrm_insecure = true
```

Provisioners (order matters):
1. `bcdedit /timeout 5`
2. `windows-update` (skip drivers/previews, cap 50)
3. Upload sysprep unattend + SetupComplete.cmd
4. Run cloudbase-init MSI silent install
5. Drop cloudbase-init.conf + cloudbase-init-unattend.conf into install dir
6. Cleanup script + WinRM reset
7. `sysprep /generalize /oobe /shutdown /unattend:...`

## Autounattend.xml key bits

- `<DiskConfiguration>` GPT for UEFI, EFI + MSR + OS partitions.
- `<DriverPaths>` referencing `$WinpeDriver$` so WinPE sees virtio-scsi disk.
- `<ImageInstall>` picks edition via `<MetaData wildcard="true">` on `/IMAGE/NAME` e.g. `Windows Server 2025 SERVERDATACENTER` or `SERVERSTANDARDCORE`.
- `<AutoLogon>` Administrator + build password, `<FirstLogonCommands>` enable WinRM for Packer.
- `<SynchronousCommand>` to auto-install VirtIO guest agent from mounted virtio ISO.

Windows Server 2022/2025 both same answer-file structure; only `/IMAGE/NAME` + ISO differ. Same Packer HCL works with var swap (`vm_os_version=2022|2025`, `vm_os_edition=SERVERDATACENTER|SERVERSTANDARD|...CORE`, `vm_boot_iso=...`).

## Clone-time parameter injection

```bash
qm clone 9000 210 --name win2025-app01 --full
qm set 210 --ipconfig0 'ip=10.0.0.50/24,gw=10.0.0.1'
qm set 210 --nameserver 10.0.0.1 --searchdomain lan
qm set 210 --ciuser Administrator --cipassword 'S3cure!Pass'
qm set 210 --sshkeys ~/.ssh/id_rsa.pub   # stored but unused on Windows
qm set 210 --ipconfig0 'ip=dhcp'         # alt
qm cloudinit update 210
qm start 210
```

Cloudbase-Init applies on first OOBE boot: hostname = VM name, admin password, NIC IP. Takes 2–3 min.

Terraform `proxmox_vm_qemu` resource: set `clone`, `cicustom`, `ciuser`, `cipassword`, `ipconfig0`, `os_type = "cloud-init"`.

## Recommended repo templates to base on

- **mfgjwaterman/Packer** — most current, 2016–2025 core+desktop, Win11 25H2, matches the Michael Waterman blog. **Best starting point**.
- **Pumba98/proxmox-packer-templates** — generic builder + per-OS pkrvars, 2019/2022/2025 + Win11.
- **EnsoIT/packer-windows-proxmox** — simpler 2022-only reference, good cloudbase pattern.
- **thundervm/proxmox-windows-template** — older but shows scripted approach without Packer.

Skip **strausmann/homelab-proxmox-templates** — Windows marked "Geplant" (planned), not implemented.

## Recommended plan

1. Fork `mfgjwaterman/Packer`. Keep `proxmox-windows-server-2022-desktop`, `-2022-core`, `-2025-desktop`, `-2025-core`.
2. Add Proxmox automation user + API token with narrow role (datastore alloc, VM alloc/config/clone/migrate, pool, snapshot).
3. Pre-upload Windows 2022 + 2025 ISOs + latest VirtIO ISO to ISO datastore.
4. Set `machine=q35`, `cpu_type=x86-64-v2-AES`, `bios=ovmf` explicitly.
5. Ensure cloudbase-init.conf has dual `metadata_services` (ConfigDrive + NoCloud) + `inject_user_password=true` + `first_logon_behaviour=no`.
6. Test: `packer init . && packer validate . && packer build .`
7. Verify clone flow with `qm set --ciuser/cipassword/ipconfig0`.
8. If password not applied → apply Proxmox plaintext patch or switch to setting password via custom user-data `cicustom`.

## Known pain points to plan for

- **Password hashing mismatch**. Test early. Fallback = `cicustom=user=local:snippets/user.yaml` with plaintext password field Cloudbase-Init reads.
- **/32 + external gateway** → Cloudbase-Init Python NetworkConfigPlugin WMI error. Patch or use /24.
- **WinRM cert** self-signed — fine for Packer, disabled at sysprep.
- **Windows Updates step slow** (30–90 min). Cache/mirror if repeating.
- **Secure Boot + virtio** — supply signed virtio drivers (virtio-win ≥ 0.1.240).

## Sources

- [From ClickOps to DevOps — Michael Waterman](https://michaelwaterman.nl/2025/12/19/from-clickops-to-devops-building-secure-windows-images-with-packer-on-proxmox/)
- [mfgjwaterman/Packer](https://github.com/mfgjwaterman/Packer)
- [Pumba98/proxmox-packer-templates](https://github.com/Pumba98/proxmox-packer-templates)
- [EnsoIT/packer-windows-proxmox](https://github.com/EnsoIT/packer-windows-proxmox)
- [ARPHost — WS2025 Cloud-Init Template](https://arphost.com/how-to-create-a-windows-server-2025-cloud-init-template-in-proxmox/)
- [ComputingForGeeks — WS2025 Proxmox guide](https://computingforgeeks.com/windows-server-template-proxmox/)
- [Proxmox forum — Packer+Cloudbase-Init cloudconfig drive fix](https://forum.proxmox.com/threads/packer-windows-cloudbase-init-os-not-seeing-cloudconfig-drive.160507/)
- [Proxmox forum — Windows cloud-init working tutorial](https://forum.proxmox.com/threads/windows-cloud-init-working.83511/)
- [Proxmox Cloud-Init Support wiki](https://pve.proxmox.com/wiki/Cloud-Init_Support)
- [strausmann/homelab-proxmox-templates](https://github.com/strausmann/homelab-proxmox-templates) (Windows planned only)
- [thundervm/proxmox-windows-template](https://github.com/thundervm/proxmox-windows-template)
- [GOAD on Proxmox part 2 — Packer templating](https://mayfly277.github.io/posts/GOAD-on-proxmox-part2-packer/)

## Interesting links

- https://schneegans.de/windows/unattend-generator/
- [Hodgkins — Best Practices with Packer and Windows - Disable WinRM on build completion and then sysprep via shutdown_command](https://hodgkins.io/blog/best-practices-with-packer-and-windows/#disable-winrm-on-build-completion-and-only-enable-it-on-first-boot)
