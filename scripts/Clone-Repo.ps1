# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

Param(
    [Parameter(Mandatory=$true)]
    [string]$Url,
    [Parameter(Mandatory=$true)]
    [string]$Secret
)

$ProgressPreference = 'SilentlyContinue'	# hide any progress output

$gitReposPath = "C:\\Repos"
if (-not (Test-Path -LiteralPath $gitReposPath))
{
    Write-Host "Creating ${gitReposPath} folder to clone git repositories..."
    $null = New-Item -Path $gitReposPath -ItemType Directory
}

# Get git install location
$gitexe = Get-Command git
$GitExeLocation = $gitexe.Source


$SecretUri = New-Object System.Uri $Secret
$KeyVaultName = $SecretUri.Host.Split('.')[0]
$SecretName = $SecretUri.AbsolutePath.Split('/')[2]

Write-Host "[${env:username}] ... Repo Url ${Url}"
Write-Host "[${env:username}] ... Secret Url ${Secret}"
Write-Host "[${env:username}] ... KeyVault Name ${KeyVaultName}"
Write-Host "[${env:username}] ... Secret Name ${SecretName}"
Write-Host "[${env:username}] ... GitExeLocation ${GitExeLocation}"

Write-Host "[${env:username}] Logging in to AZ PowerShell with VM identity ..."
Connect-AzAccount -Identity

Write-Host "[${env:username}] Getting Secret from Key Vault ..."
$SecretValue = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretName -AsPlainText

$CloneUrl = $Url.Replace('{0}', $SecretValue)

Write-Host "[${env:username}] Starting repository clone ..."
$process = Start-Process -FilePath $GitExeLocation -WorkingDirectory $gitReposPath -ArgumentList `
     "clone", `
     $CloneUrl `
     -Wait -PassThru

exit $process.ExitCode