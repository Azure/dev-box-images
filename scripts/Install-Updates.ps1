# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

Write-Host "[${env:username}] Installing PackageProvider NuGet ..."
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null

Write-Host "[${env:username}] Installing WindowsUpdate module ..."
Install-Module -Name PSWindowsUpdate -Force | Out-Null

Write-Host "[${env:username}] Install all available updates ..."
Get-WindowsUpdate -AcceptAll -Install -IgnoreReboot | FT