# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Reference: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?tabs=azure-powershell

$ProgressPreference = 'SilentlyContinue' 	# hide any progress output

$installerName = 'AzureCLI.msi'
$installerPath = Join-Path -Path $env:TEMP -ChildPath $installerName

Write-Host "[${env:username}] Downloading AzureCLI ..."
(new-object net.webclient).DownloadFile('https://aka.ms/installazurecliwindows', $installerPath)

# Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi

Write-Host "[${env:username}] Installing Azure CLI ..."
$process = Start-Process msiexec.exe -ArgumentList `
    "/I", `
    $installerPath, `
    "/quiet" `
    -Wait

# rm .\AzureCLI.msi

exit $process.ExitCode