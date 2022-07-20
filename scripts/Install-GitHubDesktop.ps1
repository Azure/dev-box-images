# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

$ProgressPreference = 'SilentlyContinue'	# hide any progress output

$installerName = "GitHubDesktopSetup-x64.msi"
$installerPath = Join-Path -Path $env:TEMP -ChildPath $installerName

Write-Host "[${env:username}] Downloading GitHub Desktop ..."
(new-object net.webclient).DownloadFile('https://central.github.com/deployments/desktop/desktop/latest/win32?format=msi', $installerPath)

Write-Host "[${env:username}] Installing GitHub Desktop ..."
$process = Start-Process msiexec.exe -ArgumentList `
	"/I", `
	$installerPath, `
	"/quiet", `
	"/qn", `
	"/norestart" `
	-NoNewWindow -Wait -PassThru

exit $process.ExitCode
