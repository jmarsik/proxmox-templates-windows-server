# Enable RDP connections and allow them through the firewall.
# Runs once via SetupComplete.cmd script called by Windows setup when VM cloned from the template
#  boots for the first time and completes OOBE.
#
# WARNING! This allows RDP from any connection profile (even Public)!

$ErrorActionPreference = 'Stop'

# Enable RDP with required Network Level Authentication (NLA).
Write-Host "Enabling RDP with NLA..."
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Value 0 -Type DWord
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name 'UserAuthentication' -Value 1 -Type DWord

# Allow RDP through the firewall.
Write-Host "Allowing RDP in Windows Firewall..."
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
