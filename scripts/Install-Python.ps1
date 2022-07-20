# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

$ProgressPreference = 'SilentlyContinue'	# hide any progress output

$pythonVersion = "3.10.5"

$installerName = "python-${pythonVersion}-amd64.exe"
$installerPath = Join-Path -Path $env:TEMP -ChildPath $installerName

Write-Host "[${env:username}] Downloading Python ${pythonVersion} ..."
(new-object net.webclient).DownloadFile("https://www.python.org/ftp/python/${pythonVersion}/python-${pythonVersion}-amd64.exe", $installerPath)

# https://docs.python.org/3/using/windows.html#installing-without-ui

Write-Host "[${env:username}] Installing Python ${pythonVersion} ..."
$process = Start-Process -FilePath $installerPath -ArgumentList `
    "/quiet", `
    "InstallAllUsers=1", `
    "PrependPath=1", `
    "Include_test=0" `
    -NoNewWindow -Wait -PassThru

exit $process.ExitCode