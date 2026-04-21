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

  # Performs Windows Update with some filters.
  # Could (and probably will) take some time and also can require 1-2 or even more reboots!
  provisioner "windows-update" {
    search_criteria = "IsInstalled=0"
    filters = [
      "exclude:$_.Title -like '*Preview*'",
      # TODO: remove... is there just to speed up testing
      #"exclude:$_.Title -like '*KB5082142*'",  # W2022
      "exclude:$_.Title -like '*KB5082063*'",  # W2025
      "exclude:$_.InstallationBehavior.CanRequestUserInput -eq $true",
      "include:$true",
    ]
    update_limit = 50
    timeout      = "2h"
  }

  provisioner "powershell" {
    inline = [
      "New-Item -Path 'C:\\Windows\\Setup\\Scripts' -ItemType Directory -Force | Out-Null",
    ]
  }

  provisioner "file" {
    source      = "./configs/sysprep-unattend.xml"
    destination = "C:\\Windows\\System32\\Sysprep\\unattend.xml"
  }

  # Upload all scripts from source directory, including SetupComplete.cmd, which is the entry point
  #  for running actions on the first boot after cloning from the template.
  provisioner "file" {
    source      = "./scripts/clone-first-boot/"
    destination = "C:\\Windows\\Setup\\Scripts\\"
  }

  # This one is special, because it runs at the end of the template build process (includes sysprep),
  #  but goes to the same target directory as the "clone-first-boot" scripts.
  # Scripts deletes itself after running, so that it's not present in the template.
  provisioner "file" {
    source      = "./scripts/post-build/disable-winrm-do-sysprep.ps1"
    destination = "C:\\Windows\\Setup\\Scripts\\disable-winrm-do-sysprep.ps1"
  }

  provisioner "powershell" {
    script = "./scripts/post-build/install-cloudbase-init.ps1"
  }

  provisioner "file" {
    source      = "./configs/cloudbase-init.conf"
    destination = "C:\\Program Files\\Cloudbase Solutions\\Cloudbase-Init\\conf\\cloudbase-init.conf"
  }

  provisioner "powershell" {
    script = "./scripts/post-build/cleanup-for-image.ps1"
  }

  # Reboot VM after previous provisioner, which performs cleanup also using DISM.
  # That really could require a reboot, which needs to be done before sysprep.
  provisioner "windows-restart" {
    timeout = "1h"
  }

  provisioner "breakpoint" {
    disable = true
    note = "before disabling of WinRM and doing sysprep"
  }

  # Poor man's way of waiting for the VM to come back including AutoLogon to interactive
  #  desktop, which happens later than WinRM being available.
  # This is VERY IMPORTANT, because the next provisioner runs sysprep, which HAS TO run
  #  in the interactive desktop session.
  provisioner "shell-local" {
    pause_before = "60s"
    inline = [
      "echo 'Waiting for VM to complete sysprep and shutdown completed.'",
    ]
  }

  provisioner "windows-shell" {
    inline = [
      "powershell.exe -ExecutionPolicy Bypass -NoLogo -NoProfile -NonInteractive -File C:\\Windows\\Setup\\Scripts\\disable-winrm-do-sysprep.ps1",
    ]
    timeout = "1h"
  }

  # Poor man's way of waiting for sysprep to complete, which can take some time.
  # Previous provisioner tears down WinRM, so Packer loses connection.
  # This just waits for the VM to complete sysprep and then shutdown on its own,
  #  which Packer then detects and continues correctly.
  provisioner "shell-local" {
    pause_before = "60s"
    inline = [
      "echo 'Waiting for VM to complete sysprep and shutdown completed.'",
    ]
  }

  provisioner "breakpoint" {
    disable = true
    note = "after sysprep"
  }
}
