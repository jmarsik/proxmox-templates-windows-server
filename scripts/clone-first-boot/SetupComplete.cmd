@echo off

rem
rem Runs on first boot after Windows setup completes OOBE.
rem Called automatically by Windows setup.
rem
rem 1) Runs PowerShell scripts in the directory, where this script is located. They have been
rem    placed there by Packer during template build process.
rem    Scripts must be named XX-*.ps1, where XX is a two-digit number specifying execution order.
rem  
rem 2) Enables Cloudbase-Init service, which then picks up config-drive with metadata to process.
rem

set "SCRIPT_DIR=%~dp0"

for /f "tokens=*" %%f in ('dir /b /o:n "%SCRIPT_DIR%*-*.ps1" 2^>nul') do (
    rem Ignore errors from scripts, to not break the whole process.
    echo Running script: %SCRIPT_DIR%%%f
    powershell.exe -ExecutionPolicy Bypass -NoLogo -NoProfile -File "%SCRIPT_DIR%%%f" || echo Error running script: %SCRIPT_DIR%%%f
)

sc.exe config cloudbase-init start=auto
sc.exe start cloudbase-init

exit /b 0
