# Final cleanup before sysprep. Removes temp files, event logs, stale WinRM
# cert/listener so sysprep doesn't bake build-time identity into the image.

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "Clearing event logs..."
Get-WinEvent -ListLog * | Where-Object { $_.RecordCount -gt 0 } | ForEach-Object {
    wevtutil cl $_.LogName
}

Write-Host "Purging temp directories..."
foreach ($p in @("$env:WinDir\Temp\*", "$env:WinDir\Prefetch\*", "$env:SystemDrive\Users\*\AppData\Local\Temp\*")) {
    Remove-Item -Recurse -Force -Path $p -ErrorAction SilentlyContinue
}

Write-Host "Running Windows disk cleanup..."
& cleanmgr.exe /sagerun:1 2>$null

Write-Host "Tearing down WinRM HTTPS listener so sysprep clears the self-signed cert..."
& winrm delete "winrm/config/Listener?Address=*+Transport=HTTPS" 2>$null
Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Subject -match "CN=$env:COMPUTERNAME" } | Remove-Item -Force

Write-Host "Cleanup done."
