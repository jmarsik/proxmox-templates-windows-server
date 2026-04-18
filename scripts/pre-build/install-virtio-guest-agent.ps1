# Install VirtIO guest tools (QEMU Guest Agent + drivers) from the mounted
# virtio-win ISO. Locates the ISO by searching all CD drives.

$ErrorActionPreference = 'Stop'
Write-Host "Searching CD drives for virtio-win-guest-tools.exe..."

$installer = $null
Get-PSDrive -PSProvider FileSystem | ForEach-Object {
    $candidate = Join-Path $_.Root 'virtio-win-guest-tools.exe'
    if (Test-Path $candidate) { $script:installer = $candidate }
}

if (-not $installer) {
    Write-Warning "virtio-win-guest-tools.exe not found on any drive; skipping."
    exit 0
}

Write-Host "Running $installer /install /norestart /quiet"
$proc = Start-Process -FilePath $installer -ArgumentList '/install','/norestart','/quiet' -Wait -PassThru
if ($proc.ExitCode -ne 0) {
    throw "virtio-win-guest-tools exited with code $($proc.ExitCode)"
}

Write-Host "VirtIO guest tools installed."
