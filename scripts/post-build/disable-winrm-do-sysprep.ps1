# Disables WinRM by removing listener and certificate
#
# Prevents sysprep from baking build-time identity into the image,
#  or leaving stale WinRM configuration if sysprep cleans up at least a part of WinRM setup.
#
# This script is uploaded to the VM and then executed as the last provisioner.
# WinRM teardown causes Packer to lose connection, but then sysprep at the end shutdowns the VM,
#  which Packer detects as successful build completion. Slight workaround is needed (just a delay)
#  to prevent Packer from shutting down the VM and continuing and converting it to template
#  shortly after it loses connection. Sysprep process still runs at that moment and have to finish
#  properly. Then it will shutdown the VM on its own. See build.pkr.hcl for details.
#
# Idea: https://hodgkins.io/blog/best-practices-with-packer-and-windows/#disable-winrm-on-build-completion-and-only-enable-it-on-first-boot

$ErrorActionPreference = 'Stop'

Write-Host "Tearing down WinRM HTTPS listener and certificate..."
& winrm delete "winrm/config/Listener?Address=*+Transport=HTTPS" 2>$null
Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Subject -match "CN=$env:COMPUTERNAME" } | Remove-Item -Force
Write-Host "WinRM HTTPS listener and certificate removed."

Write-Host "Performing sysprep..."
& "$env:WinDir\System32\Sysprep\sysprep.exe" /generalize /oobe /shutdown /unattend:C:\Windows\System32\Sysprep\unattend.xml

# At the end this script deletes itself, so that it's not left in the image.
Remove-Item -Path $MyInvocation.MyCommand.Path -Force -ErrorAction SilentlyContinue
