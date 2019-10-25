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
Write-host -Message "Configure WinRM..." -ForegroundColor Yellow
winrm quickconfig -quiet
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'

# Install NuGet required for installation of modules below
Write-host -Message "Installing required Powershell modules..." -ForegroundColor Yellow
Install-PackageProvider -Name NuGet -Force
Find-module -Name PSWindowsUpdate
Install-Module -Name PSWindowsUpdate -Force
Find-Module -Name Autologon
Install-Module -Name Autologon -Force

# Windows Updates
Write-host -Message "Apply Windows Updates..." -ForegroundColor Yellow
Copy-Item -path "a:\UpdateTask.ps1" -Destination "C:\Windows\temp\UpdateTask.ps1" -Force

$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-ExecutionPolicy Bypass -file "C:\Windows\temp\UpdateTask.ps1" -noexit'
$trigger =  New-ScheduledTaskTrigger -AtLogOn
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "PSWindowsUpdate"

Import-Module -Name Autologon -force;
Enable-AutoLogon -Username $localadminuser -Password (ConvertTo-SecureString -String $localadminpw -AsPlainText -Force) -LogonCount "1"

Write-host -Message "Rebooting..." -ForegroundColor Yellow
Restart-Computer -Force

# Reset auto logon count
# https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-autologon-logoncount#logoncount-known-issue
#Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoLogonCount -Value 0
