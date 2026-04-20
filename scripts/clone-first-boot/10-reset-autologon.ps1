# Reset autologon settings to be sure that it's disabled.
#
# We use autologon for the template build process, with higher count value, so that it logs in even
#  after multiple restart due to updates, etc. Final sysprep process needs logged in user to complete.
#
# Sysprep should reset autologon, but we want to be sure that it's really disabled.

$WinlogonRegPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
Set-ItemProperty -Path $WinlogonRegPath -Name AutoLogonCount -Value 0 -Type DWORD -ErrorAction SilentlyContinue -Force
Set-ItemProperty -Path $WinlogonRegPath -Name AutoAdminLogon -Value 0 -Type String -ErrorAction SilentlyContinue -Force
Remove-ItemProperty -Path $WinlogonRegPath -Name DefaultUserName -ErrorAction SilentlyContinue -Force
Remove-ItemProperty -Path $WinlogonRegPath -Name DefaultPassword -ErrorAction SilentlyContinue -Force
Remove-ItemProperty -Path $WinlogonRegPath -Name DefaultDomainName -ErrorAction SilentlyContinue -Force
