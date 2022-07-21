# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
$ProgressPreference = 'SilentlyContinue'    # hide any progress output

$installerName = 'Powershell7.2.5.msi'
$installerPath = Join-Path -Path $env:TEMP -ChildPath $installerName

Write-Host "[${env:username}] Downloading Powershell 7.2.5 ..."
(new-object net.webclient).DownloadFile('https://github.com/PowerShell/PowerShell/releases/download/v7.2.5/PowerShell-7.2.5-win-x64.msi', $installerPath)

Write-Host "[${env:username}] Installing Powershell 7.2.5 ..."
$process = Start-Process msiexec.exe -ArgumentList `
    "/I", `
    $installerPath, `
    "/quiet" `
    -Wait

exit $process.ExitCode