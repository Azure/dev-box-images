# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

$ProgressPreference = 'SilentlyContinue'	# hide any progress output

$eclipseVersion = "2022-06"
$eclipseDownloadName = "eclipse-jee-${eclipseVersion}.exe"
$eclipseDownloadPath = Join-Path -Path $env:TEMP -ChildPath $eclipseDownloadName
$eclipseInstallPath = "C:\Program Files"

Write-Host "[${env:username}] Downloading Eclipse ..."
$sourceUrl = "https://ftp.osuosl.org/pub/eclipse/technology/epp/downloads/release/${eclipseVersion}/R/eclipse-jee-${eclipseVersion}-R-win32-x86_64.zip"
#echo $sourceUrl
(new-object net.webclient).DownloadFile($sourceUrl, $eclipseDownloadPath)

Write-Host "[${env:username}] Unzip Eclipse ..."

Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

Unzip $eclipseDownloadPath $eclipseInstallPath 
