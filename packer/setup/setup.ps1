$ErrorActionPreference = "Stop"

# Switch network connection to private mode
# Required for WinRM firewall rules
#$profile = Get-NetConnectionProfile
#Set-NetConnectionProfile -Name $profile.Name -NetworkCategory Private

# Create a file for testing
New-Item -Path "c:\" -Name "testfile1" -ItemType "file" -Value "this is test file 1"

# Enable WinRM service
winrm quickconfig -quiet
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'

# Reset auto logon count
# https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-autologon-logoncount#logoncount-known-issue
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoLogonCount -Value 0

New-Item -Path "c:\" -Name "testfile2" -ItemType "file" -Value "this is test file 2"

