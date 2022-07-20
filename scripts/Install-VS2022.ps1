# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Details:
# - https://docs.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio?view=vs-2022
# - https://docs.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-enterprise?view=vs-2022

$ProgressPreference = 'SilentlyContinue'	# hide any progress output

$installerName = "vs_enterprise.exe"
$installerPath = Join-Path -Path $env:TEMP -ChildPath $installerName

Write-Host "[${env:username}] Downloading VS2022 ..."
(new-object net.webclient).DownloadFile('https://aka.ms/vs/17/release/vs_enterprise.exe', $installerPath)

Write-Host "[${env:username}] Installing VS2022 ..."
$process = Start-Process -FilePath $installerPath -ArgumentList `
	"--add", "Microsoft.VisualStudio.Workload.CoreEditor", `
	"--add", "Microsoft.VisualStudio.Workload.Azure", `
	"--add", "Microsoft.VisualStudio.Workload.NetWeb", `
	"--add", "Microsoft.VisualStudio.Workload.Node", `
	"--add", "Microsoft.VisualStudio.Workload.Python", `
	"--add", "Microsoft.VisualStudio.Workload.ManagedDesktop", `
	"--includeRecommended", `
	"--installWhileDownloading", `
	"--quiet", `
	"--norestart", `
	"--force", `
	"--wait", `
	"--nocache" `
	-NoNewWindow -Wait -PassThru

exit $process.ExitCode