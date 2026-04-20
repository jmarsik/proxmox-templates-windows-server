# Final cleanup before sysprep. Removes temp files, event logs, etc.

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "Clearing event logs..."
Get-WinEvent -ListLog * | Where-Object { $_.RecordCount -gt 0 } | ForEach-Object {
    try {
        Write-Host ("Clearing log: {0}" -f $_.LogName)
        wevtutil cl "$($_.LogName)"
    }
    catch {
        Write-Host ("Failed to clear {0}: {1}" -f $_.LogName, $_.Exception.Message)
    }
}

Write-Host "Purging temp directories..."
foreach ($p in @("$env:WinDir\Temp\*", "$env:WinDir\Prefetch\*", "$env:SystemDrive\Users\*\AppData\Local\Temp\*")) {
    # Exclude files starting with packer- or script- to allow Packer provisioner to correctly finish :)
    Remove-Item -Recurse -Exclude 'packer-*','script-*' -Force -Path $p -ErrorAction SilentlyContinue
}

Write-Host "Running DISM cleanup..."
# Cleanup via cleanmgr.exe with whatever options most of the time hangs for the first time
#  on a fresh image (maybe only when running from PowerShell?), so better to use something else...
# We need to mainly clean the component store after Windows Update installs, so DISM is the way to go.
# See also here: https://stackoverflow.com/questions/28852786/automate-process-of-disk-cleanup-cleanmgr-exe-without-user-intervention
& dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase | Out-Null

Write-Host "Cleanup done."

# We CANNOT cleanup WinRM here, because then Packer would not be able to connect anymore.
# Instead, we must do it as the last thing together with sysprep (+shutdown) in the last provisioner.
# See disable-winrm-do-sysprep.ps1 for details.
