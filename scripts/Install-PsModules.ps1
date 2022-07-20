# Install PowerShell modules
$modules = @(
    # "DockerMsftProvider",
    "MarkdownPS",
    # "Pester",
    "PowerShellGet",
    "PSScriptAnalyzer",
    # "PSWindowsUpdate",
    # "SqlServer",
    # "VSSetup",
    "Microsoft.Graph"
)

# Set TLS1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor "Tls12"

Write-Host "Setup PowerShellGet"
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

# Specifies the installation policy
Set-PSRepository -InstallationPolicy Trusted -Name PSGallery

foreach($module in $modules)
{
    Write-Host "Installing ${module} module"
    Install-Module -Name $module -Scope AllUsers -SkipPublisherCheck -Force
}
