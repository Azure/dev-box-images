param name string
param location string = resourceGroup().location

param gallery object

param replicaLocations array

param version string

// param subnetId string

param tempResourceGroup string = ''
param buildResourceGroup string = ''

param identity string = '/subscriptions/e5f715ae-6c72-4a5c-87c8-495590c34828/resourcegroups/Identities/providers/Microsoft.ManagedIdentity/userAssignedIdentities/Contoso'

param source object = {
  type: 'PlatformImage'
  publisher: 'microsoftwindowsdesktop'
  offer: 'windows-ent-cpc'
  sku: 'win11-21h2-ent-cpc-m365'
  version: 'latest'
}

param scriptsRepo object = {
  org: 'Azure'
  name: 'dev-box-images'
}

var scriptsRoot = 'https://raw.githubusercontent.com/${scriptsRepo.org}/${scriptsRepo.name}/main/scripts'

var resolvedResourceGroupName = empty(buildResourceGroup) ? empty(tempResourceGroup) ? '' : tempResourceGroup : buildResourceGroup

var stagingResourceGroup = empty(resolvedResourceGroupName) ? '' : '${subscription().id}/resourceGroups/${resolvedResourceGroupName}'

resource gal 'Microsoft.Compute/galleries@2022-01-03' existing = {
  name: gallery.name
  scope: resourceGroup(gallery.resourceGroup)
}

resource definition 'Microsoft.Compute/galleries/images@2022-01-03' existing = {
  name: name
  parent: gal
}

resource template 'Microsoft.VirtualMachineImages/imageTemplates@2022-02-14' = {
  name: name
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity}': {}
    }
  }
  properties: {
    // buildTimeoutInMinutes: 120 // seems to need more than 2 hours (default is 4 hours)
    stagingResourceGroup: stagingResourceGroup
    vmProfile: {
      vmSize: 'Standard_D8s_v3'
      // userAssignedIdentities:
      // vnetConfig: {
      //   subnetId: subnetId
      // }
    }
    source: source
    distribute: [
      // {
      //   type: 'ManagedImage'
      //   location: location
      //   runOutputName: '${name}-${version}-MI'
      //   imageId: resourceId(subscription().subscriptionId, resourceGroup().name, 'Microsoft.Compute/images', name)
      // }
      {
        type: 'SharedImage'
        galleryImageId: '${definition.id}/versions/${version}'
        runOutputName: '${name}-${version}-SI'
        replicationRegions: replicaLocations
        storageAccountType: 'Standard_LRS'
      }
    ]
    customize: [
      {
        type: 'PowerShell'
        inline: [
          'Write-Host "Hello World!"'
        ]
      }
      // {
      //   name: 'WindowsUpdate'
      //   type: 'WindowsUpdate'
      // }
      // {
      //   name: 'InstallPsModules'
      //   type: 'PowerShell'
      //   runElevated: true
      //   runAsSystem: true
      //   scriptUri: '${scriptsRoot}/Install-PsModules.ps1'
      // }
      // {
      //   name: 'InstallAzPsModule'
      //   type: 'PowerShell'
      //   runElevated: true
      //   runAsSystem: true
      //   scriptUri: '${scriptsRoot}/Install-AzPsModule.ps1'
      // }

      // {
      //   name: 'InstallChocolatey'
      //   type: 'PowerShell'
      //   runElevated: true
      //   runAsSystem: true
      //   scriptUri: '${scriptsRoot}/Install-Chocolatey.ps1'
      // }
      // {
      //   name: 'ChacoInstalls'
      //   type: 'PowerShell'
      //   runElevated: true
      //   runAsSystem: true
      //   inline: [
      //     // TODO: this fails with timeout error
      //     // 'choco install postman --yes --no-progress'
      //     'choco install googlechrome --yes --no-progress'
      //     'choco install firefox --yes --no-progress'
      //   ]
      // }
      // {
      //   name: 'InstallGit'
      //   type: 'PowerShell'
      //   runElevated: true
      //   runAsSystem: true
      //   scriptUri: '${scriptsRoot}/Install-Git.ps1'
      // }
      // {
      //   name: 'InstallGitHubCLI'
      //   type: 'PowerShell'
      //   runElevated: true
      //   runAsSystem: true
      //   scriptUri: '${scriptsRoot}/Install-GitHub-CLI.ps1'
      // }
      // {
      //   name: 'InstallDotNet'
      //   type: 'PowerShell'
      //   runElevated: true
      //   runAsSystem: true
      //   scriptUri: '${scriptsRoot}/Install-DotNet.ps1'
      // }
      // {
      //   name: 'InstallPython'
      //   type: 'PowerShell'
      //   runElevated: true
      //   runAsSystem: true
      //   scriptUri: '${scriptsRoot}/Install-Python.ps1'
      // }
      // {
      //   name: 'InstallGitHubDesktop'
      //   type: 'PowerShell'
      //   runElevated: true
      //   runAsSystem: true
      //   scriptUri: '${scriptsRoot}/Install-GitHubDesktop.ps1'
      // }
      // {
      //   name: 'InstallVSCode'
      //   type: 'PowerShell'
      //   runElevated: true
      //   runAsSystem: true
      //   scriptUri: '${scriptsRoot}/Install-VSCode.ps1'
      // }
      // {
      //   name: 'InstallAzureCLI'
      //   type: 'PowerShell'
      //   runElevated: true
      //   runAsSystem: true
      //   scriptUri: '${scriptsRoot}/Install-AzureCLI.ps1'
      // }
      // {
      //   name: 'InstallVS2022'
      //   type: 'PowerShell'
      //   runElevated: true
      //   scriptUri: '${scriptsRoot}/Install-VS2022.ps1'
      // }
    ]
  }
}
