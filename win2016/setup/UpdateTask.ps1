# Used for Packer process to install Windows Updates
Write-host -Message "-- Kicking off Windows Update process --" -ForegroundColor Yellow
#Modules Needed
Import-Module -name pswindowsupdate
Import-Module -Name Autologon

#Get username and password from autounattend
Write-host -Message "1) Grabbing credentials." -ForegroundColor Yellow
[xml]$xml = get-content "a:\Autounattend.xml"
$component = $xml.unattend.settings|Where-Object{$_.pass -eq "oobeSystem"}
$localadminpw = $component.component.UserAccounts.LocalAccounts.LocalAccount.Password.Value
$localadminuser = $component.component.UserAccounts.LocalAccounts.LocalAccount.name

#### Script Starts Here ####

#wait for Windows update funciton
function Test-WUInstallerStatus
{
    while ((Get-WUInstallerStatus).IsBusy)
    {
        Write-host -Message "Waiting for Windows update to become free..." -ForegroundColor Yellow
        Start-Sleep -Seconds 15
    }
}

#Enable Windows Update Service
Write-host -Message "2) Starting Windows Update Service" -ForegroundColor Yellow
write-host "Starting Windows Update Service"
Set-Service wuauserv -StartupType Automatic
Start-Service wuauserv

#Make sure no other Windows update process is running
Write-host -Message "3) Checking Windows Update Process" -ForegroundColor Yellow
write-host "Checking Windows Update Process"
Test-WUInstallerStatus

#Get Updates
Write-host -Message "4) Getting Available Updates" -ForegroundColor Yellow
write-host "Getting Available Updates"
$updates = Get-WUList

#Download and install
if($updates)
{
    Write-host -Message "5) Installing Updates" -ForegroundColor Yellow
    Write-Host "Installing Updates"
    Get-WUInstall -AcceptAll -install -IgnoreReboot
}

#Wait for Windows Update to start if needed
Start-Sleep -Seconds 5

#Make sure no other Windows update process is running
Test-WUInstallerStatus

Write-host -Message "6) Checking for reboot" -ForegroundColor Yellow
write-host "Checking for reboot"
if(Get-WURebootStatus -silent)
{
    #Needs to reboot
    #Enabling autologon
    Enable-AutoLogon -Username $localadminuser -Password (ConvertTo-SecureString -String $localadminpw -AsPlainText -Force) -LogonCount "1"
    Restart-Computer -Force
}
else
{
    #WU Reboot not needed

    #Flag to use during seal process checks
    #Not really used for now
    $good = $true


    #If checks pass
    if($good)
    {
        #Disable windows update services
        #write-host "Disabling Windows Update Service"
        #Set-Service wuauserv -StartupType Disabled
        #Stop-Service wuauserv
        #Remove Scheduled Task
        Write-host -Message "7) Removing Scheduled Task" -ForegroundColor Yellow
        write-host "Removing Scheduled Task"
        Unregister-ScheduledTask -TaskName "PSWindowsUpdate" -Confirm:$false
        #Remove update script
        remove-item "C:\Windows\temp\UpdateTask.ps1" -force

        # Reset auto logon count
        # https://docs.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-shell-setup-autologon-logoncount#logoncount-known-issue
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoLogonCount -Value 0
        
        #Try enabling HTTPS for Winrm
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1'))
    }

    #Enable CredSSP
    Enable-WSManCredSSP -Role "Server" -Force

    #Enable basic auth for vro
    winrm set winrm/config/service/auth '@{Basic="true"}'

}

