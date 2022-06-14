# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

$ProgressPreference = 'SilentlyContinue'	# hide any progress output

$ghInstallerName = "GitHubDesktopSetup-x64.exe"
$ghInstallerPath = Join-Path -Path $env:TEMP -ChildPath $ghInstallerName

Write-Host "[${env:username}] Downloading GitHub Desktop ..."
(new-object net.webclient).DownloadFile('https://central.github.com/deployments/desktop/desktop/latest/win32', $ghInstallerPath)

Write-Host "[${env:username}] Installing GitHub Desktop ..."
$process = Start-Process -FilePath $ghInstallerPath -ArgumentList "-s" -NoNewWindow -Wait -PassThru

exit $process.ExitCode
