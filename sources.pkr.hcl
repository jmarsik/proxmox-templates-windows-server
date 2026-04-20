# Two named source blocks let `packer build -only=proxmox-iso.winXXXX_desktop`
# pick the variant; both read the same variables, so the active pkrvars file
# drives the concrete ISO / vmid / edition values.

source "proxmox-iso" "win2025_desktop" {
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  token                    = var.proxmox_api_token
  insecure_skip_tls_verify = var.proxmox_skip_tls_verify
  node                     = var.proxmox_node

  vm_id                = var.vm_template_vmid
  vm_name              = var.vm_name
  template_name        = var.vm_name
  template_description = "Packer build — Windows Server ${var.vm_os_version} ${var.vm_os_edition}"
  pool                 = "Templates"
  tags                 = "packer;windows;win${var.vm_os_version};desktop"

  machine    = "q35"
  bios       = "ovmf"
  cpu_type   = "x86-64-v4"
  cores      = var.vm_cpu_cores
  memory     = var.vm_memory
  os         = "win11"
  qemu_agent = true

  scsi_controller = "virtio-scsi-single"

  efi_config {
    efi_storage_pool  = var.proxmox_storage_pool
    efi_type          = "4m"
    pre_enrolled_keys = true
  }

  network_adapters {
    model    = "virtio"
    bridge   = var.vm_bridge
    firewall = false
  }

  disks {
    type         = "scsi"
    disk_size    = var.vm_disk_size
    storage_pool = var.proxmox_storage_pool
    format       = "raw"
    io_thread    = true
    discard      = true
    ssd          = true
  }

  boot = "order=ide0;scsi0"

  boot_iso {
    type         = "ide"
    index        = 0
    iso_file     = var.vm_boot_iso
    unmount      = true
    iso_checksum = "none"
  }

  additional_iso_files {
    type             = "ide"
    index            = 1
    iso_storage_pool = var.proxmox_iso_storage_pool
    unmount          = true
    cd_files = [
      "./autounattend/${var.vm_os_version}-desktop/Autounattend.xml",
      "./scripts/pre-build/*",
    ]
  }

  additional_iso_files {
    type     = "ide"
    index    = 2
    iso_file = var.vm_virtio_iso
    unmount  = true
    iso_checksum = "none"
  }

  # Serial port for Cloudbase-Init logging besides a file-based log.
  # Useful for debugging, when you cannot log into the VM because cloud-init processing went wrong.
  serials = ["socket"]

  cloud_init              = true
  cloud_init_disk_type    = "ide"
  cloud_init_storage_pool = var.proxmox_storage_pool

  boot_wait    = "10s"
  boot_command = ["<enter><wait1s><enter><wait1s><enter><wait1s><enter><wait1s><enter>"]

  communicator   = "winrm"
  winrm_username = local.winrm_username
  winrm_password = local.build_password
  winrm_use_ssl  = true
  winrm_insecure = true
  winrm_timeout  = "6h"
  winrm_port     = 5986
}

source "proxmox-iso" "win2022_desktop" {
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  token                    = var.proxmox_api_token
  insecure_skip_tls_verify = var.proxmox_skip_tls_verify
  node                     = var.proxmox_node

  vm_id                = var.vm_template_vmid
  vm_name              = var.vm_name
  template_name        = var.vm_name
  template_description = "Packer build — Windows Server ${var.vm_os_version} ${var.vm_os_edition}"
  pool                 = "Templates"
  tags                 = "packer;windows;win${var.vm_os_version};desktop"

  machine    = "q35"
  bios       = "ovmf"
  cpu_type   = "x86-64-v4"
  cores      = var.vm_cpu_cores
  memory     = var.vm_memory
  os         = "win11"
  qemu_agent = true

  scsi_controller = "virtio-scsi-single"

  efi_config {
    efi_storage_pool  = var.proxmox_storage_pool
    efi_type          = "4m"
    pre_enrolled_keys = true
  }

  network_adapters {
    model    = "virtio"
    bridge   = var.vm_bridge
    firewall = false
  }

  disks {
    type         = "scsi"
    disk_size    = var.vm_disk_size
    storage_pool = var.proxmox_storage_pool
    format       = "raw"
    io_thread    = true
    discard      = true
    ssd          = true
  }

  boot = "order=ide0;scsi0"

  boot_iso {
    type         = "ide"
    index        = 0
    iso_file     = var.vm_boot_iso
    unmount      = true
    iso_checksum = "none"
  }

  additional_iso_files {
    type             = "ide"
    index            = 1
    iso_storage_pool = var.proxmox_iso_storage_pool
    unmount          = true
    cd_files = [
      "./autounattend/${var.vm_os_version}-desktop/Autounattend.xml",
      "./scripts/pre-build/*",
    ]
  }

  additional_iso_files {
    type     = "ide"
    index    = 2
    iso_file = var.vm_virtio_iso
    unmount  = true
    iso_checksum = "none"
  }

  # Serial port for Cloudbase-Init logging besides a file-based log.
  # Useful for debugging, when you cannot log into the VM because cloud-init processing went wrong.
  serials = ["socket"]

  cloud_init              = true
  cloud_init_disk_type    = "ide"
  cloud_init_storage_pool = var.proxmox_storage_pool

  boot_wait    = "10s"
  boot_command = ["<enter><wait1s><enter><wait1s><enter><wait1s><enter><wait1s><enter>"]

  communicator   = "winrm"
  winrm_username = local.winrm_username
  winrm_password = local.build_password
  winrm_use_ssl  = true
  winrm_insecure = true
  winrm_timeout  = "6h"
  winrm_port     = 5986
}
