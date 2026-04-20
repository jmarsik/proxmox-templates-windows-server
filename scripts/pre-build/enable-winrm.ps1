# Enable WinRM over HTTPS with a self-signed cert, so Packer can connect.
# Runs once during OOBE FirstLogonCommands when VM for template build process boots for the first time.
#
# Mostly removed later just before sysprep generalize of the template, via disable-winrm-do-sysprep.ps1.

$ErrorActionPreference = 'Stop'

Write-Host "Configuring WinRM HTTPS listener..."

Set-NetConnectionProfile -NetworkCategory Private -ErrorAction SilentlyContinue

# Create self-signed certificate for WinRM HTTPS listener, very short-lived, just for the build process.
$cert = New-SelfSignedCertificate `
    -DnsName $env:COMPUTERNAME `
    -CertStoreLocation 'Cert:\LocalMachine\My' `
    -KeyUsage DigitalSignature,KeyEncipherment `
    -KeyExportPolicy Exportable `
    -NotAfter (Get-Date).AddDays(2)

winrm quickconfig -quiet -force | Out-Null

# Remove stale HTTP listener if present
& winrm delete winrm/config/Listener?Address=*+Transport=HTTP 2>$null | Out-Null

# Create HTTPS listener
& winrm create "winrm/config/Listener?Address=*+Transport=HTTPS" "@{Hostname=`"$env:COMPUTERNAME`";CertificateThumbprint=`"$($cert.Thumbprint)`"}" | Out-Null

# Auth + transport settings
winrm set winrm/config/service/auth '@{Basic="true"}'         | Out-Null
winrm set winrm/config/client/auth  '@{Basic="true"}'         | Out-Null
winrm set winrm/config/service      '@{AllowUnencrypted="false"}' | Out-Null
winrm set winrm/config/client       '@{AllowUnencrypted="false"}' | Out-Null
winrm set winrm/config/service      '@{MaxConcurrentOperationsPerUser="4294967295"}' | Out-Null
winrm set winrm/config              '@{MaxTimeoutms="7200000"}' | Out-Null

# Firewall for WinRM HTTPS
New-NetFirewallRule -DisplayName 'WinRM HTTPS' -Direction Inbound -LocalPort 5986 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue | Out-Null

# Firewall for Core Network Diagnostics group (ICMPv4, ICMPv6)
Enable-NetFirewallRule -DisplayGroup "Core Networking Diagnostics"

# UAC remote token filtering off so Packer's Administrator works over WinRM
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'LocalAccountTokenFilterPolicy' -Value 1 -PropertyType DWord -Force | Out-Null

Set-Service -Name WinRM -StartupType Automatic
Restart-Service WinRM

Write-Host "WinRM HTTPS listener active on $env:COMPUTERNAME:5986"
