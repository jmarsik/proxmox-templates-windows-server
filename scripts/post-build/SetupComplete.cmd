@echo off
rem Runs on first boot after sysprep completes OOBE. Enables Cloudbase-Init
rem which then picks up config-drive metadata from Proxmox cloud-init.
sc.exe config cloudbase-init start= auto
sc.exe start cloudbase-init
exit /b 0
