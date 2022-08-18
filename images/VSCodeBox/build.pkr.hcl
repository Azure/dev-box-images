packer {
  required_plugins {
    # https://github.com/rgl/packer-plugin-windows-update
    windows-update = {
      version = "0.14.1"
      source  = "github.com/rgl/windows-update"
    }
  }
}

# https://www.packer.io/plugins/builders/azure/arm
source "azure-arm" "vm" {
  skip_create_image                = false
  user_assigned_managed_identities = var.identities # optional
  async_resourcegroup_delete       = true
  vm_size                          = "Standard_D8s_v3" # default is Standard_A1
  # winrm options
  communicator   = "winrm"
  winrm_username = "packer"
  winrm_insecure = true
  winrm_use_ssl  = true
  os_type        = "Windows" # tells packer to create a certificate for WinRM connection
  # base image options (Azure Marketplace Images only)
  image_publisher    = "microsoftwindowsdesktop"
  image_offer        = "windows-ent-cpc"
  image_sku          = "win11-21h2-ent-cpc-m365"
  image_version      = "latest"
  use_azure_cli_auth = true
  # managed image options
  managed_image_name                = var.name
  managed_image_resource_group_name = var.gallery.resourceGroup
  # packer creates a temporary resource group
  subscription_id          = var.subscription
  location                 = var.location
  temp_resource_group_name = var.tempResourceGroup
  # OR use an existing resource group
  build_resource_group_name = var.buildResourceGroup
  # optional use an existing key vault
  build_key_vault_name = var.keyVault
  # optional use an existing virtual network
  virtual_network_name                = var.virtualNetwork
  virtual_network_subnet_name         = var.virtualNetworkSubnet
  virtual_network_resource_group_name = var.virtualNetworkResourceGroup
  shared_image_gallery_destination {
    subscription         = var.gallery.subscription
    gallery_name         = var.gallery.name
    resource_group       = var.gallery.resourceGroup
    image_name           = var.name
    image_version        = var.version
    replication_regions  = var.replicaLocations
    storage_account_type = "Standard_LRS" # default is Standard_LRS
  }
}

build {
  sources = ["source.azure-arm.vm"]

  provisioner "powershell" {
    environment_vars = [
      "ADMIN_USERNAME=${build.User}",
      "ADMIN_PASSWORD=${build.Password}"
    ]
    script = "${path.root}/../../scripts/Enable-AutoLogon.ps1"
  }

  provisioner "windows-restart" {
    # needed to get elevated script execution working
    restart_timeout = "30m"
    pause_before    = "2m"
  }

  # https://github.com/rgl/packer-plugin-windows-update
  provisioner "windows-update" {
  }

  provisioner "powershell" {
    elevated_user     = build.User
    elevated_password = build.Password
    scripts = [
      "${path.root}/../../scripts/Install-PsModules.ps1",
      "${path.root}/../../scripts/Install-AzPsModule.ps1",
      "${path.root}/../../scripts/Install-Chocolatey.ps1"
    ]
  }

  provisioner "powershell" {
    elevated_user     = build.User
    elevated_password = build.Password
    inline = [
      // "choco install postman --yes --no-progress",
      "choco install googlechrome --yes --no-progress",
      "choco install firefox --yes --no-progress"
    ]
  }

  provisioner "powershell" {
    elevated_user     = build.User
    elevated_password = build.Password
    scripts = [
      "${path.root}/../../scripts/Install-Git.ps1",
      "${path.root}/../../scripts/Install-GitHub-CLI.ps1",
      "${path.root}/../../scripts/Install-DotNet.ps1",
      "${path.root}/../../scripts/Install-Python.ps1",
      "${path.root}/../../scripts/Install-GitHubDesktop.ps1",
      "${path.root}/../../scripts/Install-AzureCLI.ps1",
      "${path.root}/../../scripts/Install-VSCode.ps1"
    ]
  }

  // this doesn't work yet
  // provisioner "powershell" {
  //   elevated_user     = build.User
  //   elevated_password = build.Password
  //   scripts           = [for r in var.repos : "${path.root}/../../scripts/Clone-Repo.ps1 -Url '${r.url}' -Secret '${r.secret}'"]
  // }

  provisioner "powershell" {
    scripts = [
      "${path.root}/../../scripts/Disable-AutoLogon.ps1",
      "${path.root}/../../scripts/Generalize-VM.ps1"
    ]
  }
}
