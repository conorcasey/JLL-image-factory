$ErrorActionPreference = "Stop"

#Get username and password from autounattend
[xml]$xml = get-content "a:\Autounattend.xml"
$component = $xml.unattend.settings|Where-Object{$_.pass -eq "oobeSystem"}
$localadminpw = $component.component.UserAccounts.LocalAccounts.LocalAccount.Password.Value
$localadminuser = $component.component.UserAccounts.LocalAccounts.LocalAccount.name

# Switch network connection to private mode
# Required for WinRM firewall rules
$profile = Get-NetConnectionProfile
Set-NetConnectionProfile -Name $profile.Name -NetworkCategory Private

# Enable WinRM service
winrm quickconfig -quiet
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'

# Install NuGet required for installation of modules below
Install-PackageProvider -Name NuGet -Force
Find-module -Name PSWindowsUpdate
Install-Module -Name PSWindowsUpdate -Force
Find-Module -Name Autologon
Install-Module -Name Autologon -Force

# Windows Updates
Copy-Item -path "a:\UpdateTask.ps1" -Destination "C:\Windows\temp\UpdateTask.ps1" -Force

$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-ExecutionPolicy Bypass -file "C:\Windows\temp\UpdateTask.ps1" -noexit'
$trigger =  New-ScheduledTaskTrigger -AtLogOn
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "PSWindowsUpdate"

Import-Module -Name Autologon -force;
Enable-AutoLogon -Username $localadminuser -Password (ConvertTo-SecureString -String $localadminpw -AsPlainText -Force) -LogonCount "1"

Restart-Computer -Force

# Reset auto logon count
# https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-autologon-logoncount#logoncount-known-issue
#Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoLogonCount -Value 0
