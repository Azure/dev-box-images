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
    scripts           = [
      "../../scripts/Install-DotNet.ps1",
      "../../scripts/Install-AzureCLI.ps1",
      "../../scripts/Install-Powershell7.ps1",
      "../../scripts/Execute-Postscripts.ps1"
    ]
  }

  provisioner "powershell" {
    elevated_user     = build.User
    elevated_password = build.Password
    inline            = [
      "choco install sql-server-management-studio --confirm",
      "choco install notepadplusplus --confirm",
      "choco install terraform --confirm"
    ]
  }

  provisioner "windows-restart" {
    restart_timeout       = "30m"
    pause_before          = "2m"
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