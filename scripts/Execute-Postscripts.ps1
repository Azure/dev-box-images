$ProgressPreference = 'SilentlyContinue'

# Prepare the first run script
$postScriptFilePath = "C:\Program Files\Firstrun.ps1"
New-Item $postScriptFilePath -Force
Set-Content $postScriptFilePath "choco install --wsl2 --confirm `r`nchoco install wsl-ubuntu-2004 --confirm"

##### load the hive for default user and add the runone registry ######
$null = New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS

# load default user
$null = reg load HKU\TestHive "C:\Users\Default\NTUSER.DAT"

# create folder Runonce
$regHKURunonceParentPath = "HKU:\TestHive\Software\Microsoft\Windows\CurrentVersion"
$runonceName = "Runonce"
New-Item -Path $regHKURunonceParentPath  -Name $runonceName -Force

$regHKURunoncePath = "$regHKURunonceParentPath\$runonceName"
$firstRunKey = "firstrun"
$firstRunValue = "PowerShell $postScriptFilePath"
New-ItemProperty -Path $regHKURunoncePath -Name $firstRunKey -Value $firstRunValue -PropertyType String -Force 

[gc]::collect()
$null = reg unload HKU\TestHive
$null = Remove-PSDrive -Name HKU