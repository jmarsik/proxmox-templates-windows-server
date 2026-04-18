packer {
  required_version = ">= 1.11.0"

  required_plugins {
    proxmox = {
      version = ">= 1.2.2"
      source  = "github.com/hashicorp/proxmox"
    }
    windows-update = {
      version = ">= 0.14.0"
      source  = "github.com/rgl/windows-update"
    }
  }
}

locals {
  build_password = "P@ssw0rd!"
  winrm_username = "Administrator"

  template_vmids = {
    "2022" = 9022
    "2025" = 9025
  }
}
