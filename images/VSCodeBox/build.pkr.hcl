build {

  # use source defined in the source.pkr.hcl file
  sources = ["source.azure-arm.vm"]

  provisioner "powershell" {
    environment_vars  = [
      "ADMIN_USERNAME=${build.User}",
      "ADMIN_PASSWORD=${build.Password}" ]
    script            = "../../scripts/Enable-AutoLogon.ps1"
  }

  provisioner "windows-restart" {
    # needed to get elevated script execution working
    restart_timeout       = "30m"
    pause_before          = "2m"
  }

  provisioner "powershell" {
    elevated_user     = build.User
    elevated_password = build.Password
    script            = "../../scripts/Install-Updates.ps1"
  }

  provisioner "windows-restart" {
    # needed to get finalize updates with reboot required
    restart_timeout       = "30m"
    pause_before          = "2m"
  }

  provisioner "powershell" {
    elevated_user     = build.User
    elevated_password = build.Password
    script            = "../../scripts/Install-Chocolatey.ps1"
  }

  provisioner "powershell" {
    elevated_user     = build.User
    elevated_password = build.Password
    inline            = [
      "choco install git --confirm",
      "choco install adoptopenjdk8 --confirm",
      "choco install maven --confirm",
      "choco install postman --confirm",
      "choco install googlechrome --confirm"
    ]
  }

  provisioner "powershell" {
    elevated_user     = build.User
    elevated_password = build.Password
    scripts           = [
      "../../scripts/Install-Python3.8.ps1",
      "../../scripts/Install-AzureCLI.ps1",
      "../../scripts/Install-VSCode.ps1",
      "../../scripts/Install-HyperV.ps1",
      "../../scripts/Install-Eclipse.ps1",   
      "../../scripts/Install-GCloudCLI.ps1"  # depends on python
    ]
  }

  provisioner "powershell" {
    scripts = [
      "../../scripts/Disable-AutoLogon.ps1",
      "../../scripts/Generalize-VM.ps1"
    ]
  }

  post-processor "shell-local" {
    inline  = [ "az image delete -g ${var.resourceGroup} -n ${var.image}" ]
  }
}
