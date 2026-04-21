# TODO

* X Check Windows channel, activation status, rearm count, product key, etc. with `slmgr.vbs /dlv`. ... Done, added instructions to README.md.
* Remove Windows Update exclusion filter used to speed up testing.
* X AutoLogonCount reset after first boot? Check the value and behavior. ... Yes, sysprep resets the functionality, but AutoLogonCount remains 1. But it's blocked by AutoAdminLogon 0, so it doesn't cause issues. But still not ideal, so we will reset it to 0 to be safe.
* X SSH instead of WinRM? ... Done.
* X Real time clock UTC vs local time? Check consequences in Proxmox, Windows. Related to QEMU Guest Agent time sync vs NTP. ... For Windows guest, Proxmox sets RTC to local time, and Cloudbase-Init doesn't change it, so it stays in local time. This is expected and works fine.
  * Relevant: [Windows Active Directory (AD) as VM on Proxmox Time Issues
](https://www.reddit.com/r/Proxmox/comments/1rg8jdr/windows_active_directory_ad_as_vm_on_proxmox_time/)
* X Check `cicustom` with file snippets instead of volumes in Proxmox. Or custom generated ISO. ... Can be done, but snippets are not available via Proxmox API, so would require manual upload and maintenance. Not ideal. There are custom API endpoints for installation on Proxmox hosts, also not ideal. One can prepare cloud-init ISO himself, upload to Proxmox via API or UI, and then use either `cicustom` or manual attachment of the ISO as a CDROM drive. Pending further testing.
* X Check **Generation ID** via PVE VM Monitor tab before and after cloning. Command is `info vm-generation-id`. Must be *different*. ... Yes, it's different, good.
* X Eject cloud-init CDROM after it's completely done? Or stop service and set to disabled or even uninstall? ... For now mentioned in README.md, but ideally should be automated in some way to avoid issues with subsequent boots (re-applying some settings).
