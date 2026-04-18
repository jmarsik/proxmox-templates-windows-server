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

  machine  = "q35"
  bios     = "ovmf"
  cpu_type = "x86-64-v2-AES"
  cores    = var.vm_cpu_cores
  memory   = var.vm_memory
  os       = "win11"
  qemu_agent = true

  scsi_controller = "virtio-scsi-single"

  efi_config {
    efi_storage_pool  = var.proxmox_storage_pool
    efi_type          = "4m"
    pre_enrolled_keys = false
  }

  network_adapters {
    model    = "virtio"
    bridge   = var.vm_bridge
    firewall = false
  }

  disks {
    type              = "scsi"
    disk_size         = var.vm_disk_size
    storage_pool      = var.proxmox_storage_pool
    format            = "raw"
    io_thread         = true
    discard           = true
    ssd               = true
  }

  boot_iso {
    type         = "ide"
    iso_file     = var.vm_boot_iso
    unmount      = true
    iso_checksum = "none"
  }

  additional_iso_files {
    type     = "ide"
    index    = 3
    iso_file = var.vm_virtio_iso
    unmount  = true
  }

  additional_iso_files {
    type             = "ide"
    index            = 2
    iso_storage_pool = var.proxmox_iso_storage_pool
    unmount          = true
    cd_files = [
      "./autounattend/${var.vm_os_version}-desktop/Autounattend.xml",
      "./scripts/pre-build/*",
    ]
    cd_content = {
      "ignore.txt" = "cd_files placeholder\n"
    }
  }

  boot_wait    = "10s"
  boot_command = ["<enter>"]

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

  machine  = "q35"
  bios     = "ovmf"
  cpu_type = "x86-64-v2-AES"
  cores    = var.vm_cpu_cores
  memory   = var.vm_memory
  os       = "win11"
  qemu_agent = true

  scsi_controller = "virtio-scsi-single"

  efi_config {
    efi_storage_pool  = var.proxmox_storage_pool
    efi_type          = "4m"
    pre_enrolled_keys = false
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

  boot_iso {
    type         = "ide"
    iso_file     = var.vm_boot_iso
    unmount      = true
    iso_checksum = "none"
  }

  additional_iso_files {
    type     = "ide"
    index    = 3
    iso_file = var.vm_virtio_iso
    unmount  = true
  }

  additional_iso_files {
    type             = "ide"
    index            = 2
    iso_storage_pool = var.proxmox_iso_storage_pool
    unmount          = true
    cd_files = [
      "./autounattend/${var.vm_os_version}-desktop/Autounattend.xml",
      "./scripts/pre-build/*",
    ]
    cd_content = {
      "ignore.txt" = "cd_files placeholder\n"
    }
  }

  boot_wait    = "10s"
  boot_command = ["<enter>"]

  communicator   = "winrm"
  winrm_username = local.winrm_username
  winrm_password = local.build_password
  winrm_use_ssl  = true
  winrm_insecure = true
  winrm_timeout  = "6h"
  winrm_port     = 5986
}
