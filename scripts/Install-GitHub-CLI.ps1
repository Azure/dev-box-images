# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

$installerName = "gh_windows_amd64.msi"
$installerPath = Join-Path -Path $env:TEMP -ChildPath $installerName

Write-Host "[${env:username}] Getting latest version of GitHub CLI ..."
$assets = (Invoke-RestMethod -Uri "https://api.github.com/repos/cli/cli/releases/latest").assets
$downloadUrl = ($assets.browser_download_url -match "windows_amd64.msi") | Select-Object -First 1

Write-Host "[${env:username}] Downloading latest version of GitHub CLI ..."
(new-object net.webclient).DownloadFile($downloadUrl, $installerPath)

Write-Host "[${env:username}] Installing GitHub CLI ..."
$process = Start-Process msiexec.exe -ArgumentList `
	"/I", `
	$installerPath, `
	"/qn", `
	"/norestart" `
	-NoNewWindow -Wait -PassThru

$currentPath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
$newPath = "C:\Program Files (x86)\GitHub CLI" + ';' + $currentPath
[System.Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")

exit $process.ExitCode
