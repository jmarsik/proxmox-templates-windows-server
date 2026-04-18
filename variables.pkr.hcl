variable "proxmox_url" {
  type        = string
  description = "Proxmox API endpoint, e.g. https://pve01.lan:8006/api2/json"
}

variable "proxmox_username" {
  type        = string
  description = "Proxmox API token user, e.g. packer@pve!packer"
}

variable "proxmox_api_token" {
  type        = string
  sensitive   = true
  description = "Proxmox API token secret (set via PKR_VAR_proxmox_api_token)"
}

variable "proxmox_node" {
  type        = string
  description = "Proxmox node name to build on"
}

variable "proxmox_storage_pool" {
  type        = string
  description = "Storage pool for VM disks and EFI disk"
}

variable "proxmox_iso_storage_pool" {
  type        = string
  description = "Storage pool for generated cd_files ISO"
}

variable "proxmox_skip_tls_verify" {
  type        = bool
  default     = true
  description = "Skip TLS verify on Proxmox API (homelab self-signed)"
}

variable "vm_boot_iso" {
  type        = string
  description = "Windows installer ISO reference, e.g. local:iso/SERVER_2025_EVAL_x64FRE_en-us.iso"
}

variable "vm_virtio_iso" {
  type        = string
  description = "VirtIO drivers ISO reference, e.g. local:iso/virtio-win-0.1.266.iso"
}

variable "vm_os_version" {
  type        = string
  description = "Windows Server version: 2022 or 2025"
  validation {
    condition     = contains(["2022", "2025"], var.vm_os_version)
    error_message = "The vm_os_version must be 2022 or 2025."
  }
}

variable "vm_os_edition" {
  type        = string
  default     = "SERVERDATACENTER"
  description = "Windows image edition picked by Autounattend (SERVERDATACENTER, SERVERSTANDARD, …CORE)"
}

variable "vm_name" {
  type        = string
  description = "Template VM name"
}

variable "vm_template_vmid" {
  type        = number
  description = "Template VM ID"
}

variable "vm_disk_size" {
  type        = string
  default     = "80G"
  description = "OS disk size"
}

variable "vm_cpu_cores" {
  type        = number
  default     = 2
  description = "vCPU cores"
}

variable "vm_memory" {
  type        = number
  default     = 4096
  description = "RAM in MB"
}

variable "vm_bridge" {
  type        = string
  default     = "vmbr0"
  description = "Network bridge for the build VM"
}
