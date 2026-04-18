# Download + install Cloudbase-Init MSI silently. Service left in Manual state;
# SetupComplete.cmd flips it to Automatic on first post-sysprep boot.

$ErrorActionPreference = 'Stop'

$msiUrl = 'https://cloudbase.it/downloads/CloudbaseInitSetup_Stable_x64.msi'
$msiPath = Join-Path $env:TEMP 'CloudbaseInitSetup.msi'
$logPath = Join-Path $env:TEMP 'CloudbaseInitSetup.log'

Write-Host "Downloading $msiUrl ..."
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath -UseBasicParsing

Write-Host "Installing Cloudbase-Init ..."
$args = @(
    '/i', "`"$msiPath`"",
    '/qn',
    '/l*v', "`"$logPath`"",
    'LOGGINGSERIALPORTNAME=',
    'INSTALLDIR="C:\Program Files\Cloudbase Solutions\Cloudbase-Init\"'
)
$proc = Start-Process -FilePath 'msiexec.exe' -ArgumentList $args -Wait -PassThru
if ($proc.ExitCode -ne 0) {
    Get-Content $logPath -Tail 80 | Write-Host
    throw "Cloudbase-Init MSI exit code $($proc.ExitCode); see $logPath"
}

Set-Service -Name cloudbase-init -StartupType Manual
Write-Host "Cloudbase-Init installed; service left in Manual state pending sysprep."
