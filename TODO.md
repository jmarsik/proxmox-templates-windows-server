# TODO

* Check Windows channel, activation status, rearm count, product key, etc. with `slmgr.vbs /dlv`.
* Remove Windows Update exclusion filter used to speed up testing.
* X AutoLogonCount reset after first boot? Check the value and behavior.
* X SSH instead of WinRM?
* Real time clock UTC vs local time? Check consequences in Proxmox, Windows. Related to QEMU Guest Agent time sync vs NTP.
* Check `cicustom` with file snippets instead of volumes in Proxmox. Or custom generated ISO.
* Check **Generation ID** via PVE VM Monitor tab before and after cloning. Command is `info vm-generation-id`. Must be *different*.
* Eject cloud-init CDROM after it's completely done? Or stop service and set to disabled or even uninstall?

