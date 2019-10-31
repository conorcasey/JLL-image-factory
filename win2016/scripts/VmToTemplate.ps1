<#
.SYNOPSIS
  Name: VmToTemplate.ps1
  Purpose: Convert Packer generates vm to a template

.DESCRIPTION
  Convert Packer generates vm to a template

.NOTES
    Updated: 10/31/2019
    Release Date:

    Author: Ahead, LLC
    Contributors: 
    Company: 

#>


#Connect to vCenter server
Write-Output "`nConnecting to vCenter : $env:VSPHERE_SERVER"
try {
    Connect-VIServer -Server $env:VSPHERE_SERVER -User $env:VSPHERE_USERNAME -Password $env:VSPHERE_PASSWORD -ErrorAction Stop
}
catch {
    throw "Failed to connect to vCenter : $($error[0])"
}


$manifest = get-content "./manifest.json"|ConvertFrom-Json
$newtemp = $manifest.builds[0].artifact_id

$convertname = $env:FRIENDLYNAME



#Verify new template exists
try{
    $newtemplate = Get-VM -Name $newtemp -ErrorAction Stop
}
catch
{
    throw "$newtemp template is missing!"
}

Write-host "Found $newtemp!"

#Checks for a .old template
try{
    $oldtemplate = Get-Template -Name "${convertname}.old" -ErrorAction Continue
}
catch
{
    $oldtemplate = $false
}

#Removes previous .old template if found
if($oldtemplate)
{
    Write-Host "Removing $oldtemplate"
    Remove-Template -Template $oldtemplate -Confirm:$false -DeletePermanently
}
else {
    Write-Host "$oldtemplate not found"
}

#Rename current template to .old version
write-host "Renaming $convertname to ${convertname}.old"
$convertname|Set-Template -name "${convertname}.old"


#Set note
$date = get-date
$note = "Build Date: $date`nADO Build: $(env:Build.BuildId)`nADO Job: $(env:Build.BuildUri)"
$newtemplate|Set-VM -note $note -Confirm:$false

#Convert to template
write-host "Converting to template"
$newtemplate = $newtemplate|Set-VM -ToTemplate -Confirm:$false

#Renames template
write-host "Renaming $newtemplate to $convertname"
$newtemplate|Set-Template -name $convertname
