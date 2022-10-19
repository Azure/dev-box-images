# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Reference: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-windows?tabs=azure-powershell

$ProgressPreference = 'SilentlyContinue' 	# hide any progress output

$installerName = 'GoogleCloudSDKInstaller..exe'
$installerPath = Join-Path -Path $env:TEMP -ChildPath $installerName

Write-Host "[${env:username}] Downloading GCloud CLI ..."
(new-object net.webclient).DownloadFile('https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe', $installerPath)

Write-Host "[${env:username}] Installing GCloud CLI ..."
$process = Start-Process -FilePath $installerPath -ArgumentList `
    "/S" `
    -NoNewWindow -Wait -PassThru

exit $process.ExitCode

