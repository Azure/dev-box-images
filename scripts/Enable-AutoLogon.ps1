# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Stop script execution when a non-terminating error occurs
$ErrorActionPreference = "Stop"

If ([string]::IsNullOrEmpty($Env:ADMIN_USERNAME)) { Throw "Env:ADMIN_USERNAME must be set" }
If ([string]::IsNullOrEmpty($Env:ADMIN_PASSWORD)) { Throw "Env:ADMIN_PASSWORD must be set" }

# Our testing has shown that Windows 10 does not allow packer to run a Windows scheduled task until the admin user (packer) has logged into the system.
# So we enable AutoAdminLogon and use packer's windows-restart provisioner to get the system into a good state to allow scheduled tasks to run.

Write-Output "Enabling AutoAdminLogon to allow packer's scheduled task created by elevated_user to run..."
Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name AutoAdminLogon -Value 1 -type String
Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultUsername -Value "$Env:ADMIN_USERNAME" -type String
Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name DefaultPassword -Value "$Env:ADMIN_PASSWORD" -type String