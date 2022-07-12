packer {
  required_plugins {
    # https://github.com/rgl/packer-plugin-windows-update
    windows-update = {
      version = "0.14.1"
      source = "github.com/rgl/windows-update"
    }
  }
}

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

  # https://github.com/rgl/packer-plugin-windows-update
  provisioner "windows-update" {
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
      "choco install postman --confirm",
      "choco install googlechrome --confirm",
      "choco install firefox --confirm"
    ]
  }

  provisioner "powershell" {
    elevated_user     = build.User
    elevated_password = build.Password
    scripts           = [
      "../../scripts/Install-DotNet.ps1",
      "../../scripts/Install-Python.ps1",
      "../../scripts/Install-GitHubDesktop.ps1",
      "../../scripts/Install-AzureCLI.ps1",
      "../../scripts/Install-VSCode.ps1"
    ]
  }

  provisioner "powershell" {
    scripts = [
      "../../scripts/Disable-AutoLogon.ps1",
      "../../scripts/Generalize-VM.ps1"
    ]
  }
}
