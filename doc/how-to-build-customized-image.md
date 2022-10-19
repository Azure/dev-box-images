# Quick guide for the customized image

This is the quick guide about how to geneate the customized image for Dev Box.
The main steps are as below:
- Create a Gallery
- Configure for Gallery
- Create Service Principal
- Generate the image

## Create a Gallery
1. Search "Azure Compute Galleries" in the Azure Portal, click the service "Azure compute galleries"
![Search Gallery](/doc/media/search-azure-compute-gallery.png)

2.	Click the "Create" button
![Create Gallery](/doc/media/create-azure-compute-gallery.png)

3.	Give the gallery name and select the resource group, then click "Review + Create"
![Create Gallery Detail](/doc/media/create-azure-compute-gallery-detail.png)

## Configure for Gallery
1.	Fork the base repository [Azure/dev-box-images](https://github.com/Azure/dev-box-images)
![Fork Base repo](/doc/media/fork-base-repo.png)

2.	In your forked repository, change the value in gallery.yml:

name: "the gallery name that we just created in the above step"
resourceGroup: "the resource group that the gallery is located"

Please check the mapping as below:
![Update Gallery Yml](/doc/media/update-gallery-yml.png)

## Create Service Principal

1.	Create a Service Principal with the Azure CLI command as below:

az ad sp create-for-rbac --sdk-auth --role contributor --scopes /subscriptions/<subscription id>  -n <your  service principal name>

You will get the output as below:
{
  "clientId": "<GUID>",
  "clientSecret": "<STRING>",
  "subscriptionId": "<GUID>",
  "tenantId": "<GUID>"
  (...)
}

Remove all the line breaks and keep a single link as below:
{ "clientId": "<GUID>", "clientSecret": "<GUID>", "subscriptionId": "<GUID>", "tenantId": "<GUID>", (...) }

2.	Go to the settings of your forked GitHub project
![GitHub Repo Setting](/doc/media/github-repo-settings.png)

3.	Click "Secrets" -> "Actions" -> "New Repository Secret"
![New Repository Secret](/doc/media/new-repo-secret.png)

Secret name is "AZURE_CREDENTIALS". Value is the single line that we prepared before as below:
{ "clientId": "<GUID>", "clientSecret": "<GUID>", "subscriptionId": "<GUID>", "tenantId": "<GUID>", (...) }

## Generate the image
1.	Go to the forked GitHub project’s "Actions" page
![GitHub Actions](/doc/media/github-actions.png)

Enable it if there is an option asking to click.

2.	Define the software to install
Go to images/VSCodeBox/build.pkr.hcl
If the software can be installed by choco, just execute the command "choco install" to install.
Note: --confirm is required otherwise, it will be installed by confirm yes or no.
If the software cannot be installed by choco, please write up the related PowerShell script to install the specific software.

![Customize Software](/doc/media/cutomize-software.png)

Once you commit the change under the folder images or scripts, the GitHub action pipeline will be triggered.

3.	Go to the GitHub Actions, you will see the status of the pipeline
![GitHub Actions Workflow](/doc/media/github-actions-workflow.png)
