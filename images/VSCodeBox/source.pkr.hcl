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
  managed_image_name                = var.image
  managed_image_resource_group_name = var.galleryResourceGroup
  location                          = var.location
  temp_resource_group_name          = var.tempResourceGroup
  build_resource_group_name         = var.buildResourceGroup
  async_resourcegroup_delete        = true
  os_type                           = "Windows"
  vm_size                           = "Standard_D8s_v3"
  shared_image_gallery_destination {
    subscription         = var.subscription
    resource_group       = var.galleryResourceGroup
    gallery_name         = var.galleryName
    image_name           = var.image
    image_version        = var.version
    replication_regions  = var.replicaLocations
    storage_account_type = "Standard_LRS"
  }
}
