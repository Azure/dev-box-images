# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

$ProgressPreference = 'SilentlyContinue'	# hide any progress output

$vsInstallerName = "vs_code.exe"
$vsInstallerPath = Join-Path -Path $env:TEMP -ChildPath $vsInstallerName

Write-Host "[${env:username}] Downloading VSCode ..."
(new-object net.webclient).DownloadFile('https://code.visualstudio.com/sha/download?build=stable&os=win32-x64', $vsInstallerPath)

Write-Host "[${env:username}] Installing VSCode ..."
$process = Start-Process -FilePath $vsInstallerPath -ArgumentList `
	"/VERYSILENT", `
	"/NORESTART", `
	"/MERGETASKS=!runcode" `
	-NoNewWindow -Wait -PassThru

exit $process.ExitCode
