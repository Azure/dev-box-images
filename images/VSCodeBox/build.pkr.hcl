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
  azure_tags = {
    branch = var.branch
    build  = timestamp()
    commit = var.commit
  }
  communicator                      = "winrm"
  winrm_username                    = "packer"
  winrm_insecure                    = true
  winrm_use_ssl                     = true
  image_publisher                   = "microsoftwindowsdesktop"
  image_offer                       = "windows-ent-cpc"
  image_sku                         = "win11-21h2-ent-cpc-m365"
  image_version                     = "latest"
  use_azure_cli_auth                = true
  managed_image_name                = var.name
  managed_image_resource_group_name = var.gallery.resourceGroup
  location                          = var.location
  temp_resource_group_name          = var.tempResourceGroup
  build_resource_group_name         = var.buildResourceGroup
  user_assigned_managed_identities  = var.identities
  async_resourcegroup_delete        = true
  os_type                           = "Windows"
  vm_size                           = "Standard_D8s_v3"
  shared_image_gallery_destination {
    subscription         = var.subscription
    gallery_name         = var.gallery.name
    resource_group       = var.gallery.resourceGroup
    image_name           = var.name
    image_version        = var.version
    replication_regions  = var.replicaLocations
    storage_account_type = "Standard_LRS"
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

  provisioner "file" {
     source = "./packages/packages.config"
     destination = "C:/Windows/Temp/packages.config"
  }

  provisioner "powershell" {
    elevated_user     = build.User
    elevated_password = build.Password
    inline = [
      "choco install C:/Windows/Temp/packages.config --yes --no-progress"
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
