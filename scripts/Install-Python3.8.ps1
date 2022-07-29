# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

$ProgressPreference = 'SilentlyContinue'	# hide any progress output

$pythonVersion = "3.8.10"

$installerName = "python-${pythonVersion}-amd64.exe"
$InstallerPath = Join-Path -Path $env:TEMP -ChildPath $installerName

Write-Host "[${env:username}] Downloading Python ${pythonVersion} ..."
(new-object net.webclient).DownloadFile("https://www.python.org/ftp/python/${pythonVersion}/python-${pythonVersion}-amd64.exe", $InstallerPath) 

Write-Host "[${env:username}] Installing Python ${pythonVersion} ..."
$process = Start-Process -FilePath $installerPath -ArgumentList `
    "/quiet" `
    -NoNewWindow -Wait -PassThru

exit $process.ExitCode