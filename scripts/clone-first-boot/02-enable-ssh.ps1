# Enable SSH connections and allow them through the firewall.
# Runs once via SetupComplete.cmd script called by Windows setup when VM cloned from the template
#  boots for the first time and completes OOBE.
#
# WARNING! This allows SSH from any connection profile (even Public)!

$ErrorActionPreference = 'Stop'

# Check if OpenSSH Server capability is available.
# It's present by default in Windows Server 2025 and later. In older versions it has to be
#  added via download and that requires internet connection.
# We skip it for now if not present.
if ((Get-WindowsCapability -Name OpenSSH.Server -Online -ErrorAction SilentlyContinue).State -ne 'Installed') {
    Write-Host "OpenSSH Server capability not found. Skipping..."
    return
}

# Enable SSH.
Write-Host "Enabling SSH..."
Set-Service -Name sshd -StartupType Automatic
Start-Service sshd

# Change default shell to PowerShell.
Write-Host "Changing default shell for SSH to PowerShell..."
New-ItemProperty -Path 'HKLM:\SOFTWARE\OpenSSH' -Name DefaultShell -Value 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -PropertyType String -Force | Out-Null

# Allow SSH through the firewall.
Write-Host "Allowing SSH in Windows Firewall..."
Enable-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue
# On Windows Server 2025 and later, the rule seems to have only Private profile enabled by default.
# We want to allow SSH for all profiles.
Set-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -Profile Any -ErrorAction SilentlyContinue

# Disable questionable default SSH server setting (when installed on Windows).
# See C:\ProgramData\ssh\sshd_config for details. The setting in question is at the end of the file:
#
# Match Group administrators
#       AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys
#
# It requires that any user in the administrators (case insensitive) group must have
#  their public key present in their own ~/.ssh/authorized_keys file, and ALSO in the separate file
#  C:\ProgramData\ssh\administrators_authorized_keys to be able to log in over SSH.
#
# The reasoning is thoroughly discussed here:
# - https://github.com/PowerShell/Win32-OpenSSH/issues/1324
# - https://github.com/cloudbase/cloudbase-init/issues/162
#
# We opt to disable this setting, for "server" use case of the templates it makes less sense.
$sshdConfigPath = 'C:\ProgramData\ssh\sshd_config'
$content = Get-Content -Path $sshdConfigPath -Raw
$content = $content -replace '(?im)^([^\r\n\S]*Match[^\r\n\S]+Group[^\r\n\S]+administrators[^\r\n\S]*\r?\n)([^\r\n\S]+AuthorizedKeysFile[^\r\n\S]+__PROGRAMDATA__/ssh/administrators_authorized_keys)','# $1# $2'
Set-Content -Path $sshdConfigPath -Value $content -NoNewline

# Restart SSH service to apply changes.
Restart-Service sshd
