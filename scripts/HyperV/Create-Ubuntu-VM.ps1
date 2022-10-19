# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

Param(
    [Parameter(Mandatory=$false)]
    [string]$Vm_Path= "C:\HyperVms",
    [Parameter(Mandatory=$false)]
    [string]$Vm_Name= "UbuntuVM",
    [Parameter(Mandatory=$false)]
    [string]$Vm_Vhd
)


$ProgressPreference = 'SilentlyContinue'	# hide any progress output

$fullpath = Join-Path -Path $Vm_Path -ChildPath $Vm_Name

if (!(Test-Path -Path $fullpath )) {
    New-Item -Path $Vm_Path -Name $Vm_Name -ItemType Directory | Out-Null
}

$VhdToAttach = ""

# If the vm_vhd isn't passed in then download the ubuntu vhd 
if ($Vm_Vhd) {
    $VhdToAttach = $Vm_Vhd
}
else 
{
    Write-Host "Downloading Ubuntu vhd"
    $ubuntuDownload = "https://partner-images.canonical.com/hyper-v/desktop/focal/release/current/ubuntu-focal-hyperv-amd64-ubuntu-desktop-hyperv.vhdx.zip"
    $ubuntuFile = "ubuntu.zip"
    $fullUbuntuZip = Join-Path $fullpath -ChildPath $ubuntuFile

    # Download Ubuntu file
    Invoke-WebRequest $ubuntuDownload -UseBasicParsing -OutFile "$($fullUbuntuZip)"
    Write-Host "Extracting files"
    # Unzip file
    Expand-Archive -LiteralPath $fullUbuntuZip -DestinationPath $fullpath -Force

    # Get the .vhdx
    $vhd = Get-ChildItem $fullpath -Include *.vhdx -Recurse

    $VhdToAttach = $vhd.FullName

}

# Create vm
Write-Host "Creating Hosted vm $Vm_Name"
New-VM -Name $Vm_Name -MemoryStartupBytes 4096MB -Path $fullpath | Out-Null

Write-Host "Attaching drive to hosted vm."
Add-VMHardDiskDrive -VMName $Vm_Name -Path $VhdToAttach

Write-Host "Connect default network"
Connect-VMNetworkAdapter -VMName $Vm_Name -SwitchName 'default switch'

Write-Host "Enable VM Integration"
Get-VMIntegrationService -VMName $vm_Name | ? Name -match 'Interface' | Enable-VMIntegrationService

Write-Host "Increase processors and Enable processor compatibility"
Set-VMProcessor -VMName $Vm_Name -CompatibilityForMigrationEnabled 1 -Count 2