build {
  name = "proxmox-windows"

  sources = [
    "source.proxmox-iso.win2025_desktop",
    "source.proxmox-iso.win2022_desktop",
  ]

  provisioner "powershell" {
    inline = [
      "bcdedit /timeout 5",
      "Set-TimeZone -Id 'UTC'",
    ]
  }

  provisioner "windows-update" {
    search_criteria = "IsInstalled=0"
    filters = [
      "exclude:$_.Title -like '*Preview*'",
      "exclude:$_.InstallationBehavior.CanRequestUserInput -eq $true",
      "include:$true",
    ]
    update_limit = 50
  }

  provisioner "powershell" {
    inline = [
      "New-Item -Path 'C:\\Windows\\Panther\\Unattend' -ItemType Directory -Force | Out-Null",
      "New-Item -Path 'C:\\Windows\\Setup\\Scripts'  -ItemType Directory -Force | Out-Null",
    ]
  }

  provisioner "file" {
    source      = "./configs/sysprep-unattend.xml"
    destination = "C:\\Windows\\Panther\\Unattend\\unattend.xml"
  }

  provisioner "file" {
    source      = "./scripts/post-build/SetupComplete.cmd"
    destination = "C:\\Windows\\Setup\\Scripts\\SetupComplete.cmd"
  }

  provisioner "powershell" {
    script = "./scripts/post-build/install-cloudbase-init.ps1"
  }

  provisioner "file" {
    source      = "./configs/cloudbase-init.conf"
    destination = "C:\\Program Files\\Cloudbase Solutions\\Cloudbase-Init\\conf\\cloudbase-init.conf"
  }

  provisioner "file" {
    source      = "./configs/cloudbase-init-unattend.conf"
    destination = "C:\\Program Files\\Cloudbase Solutions\\Cloudbase-Init\\conf\\cloudbase-init-unattend.conf"
  }

  provisioner "powershell" {
    script = "./scripts/post-build/cleanup-for-image.ps1"
  }

  provisioner "windows-shell" {
    inline = [
      "C:\\Windows\\System32\\Sysprep\\sysprep.exe /generalize /oobe /shutdown /unattend:C:\\Windows\\Panther\\Unattend\\unattend.xml",
    ]
  }
}
