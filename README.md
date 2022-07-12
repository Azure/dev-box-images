# Dev Box Images

This repo contains custom images to be used with [Microsoft Dev Box](https://techcommunity.microsoft.com/t5/azure-developer-community-blog/introducing-microsoft-dev-box/ba-p/3412063).  It demonstrates how to create custom images with pre-installed software using [Packer](https://www.packer.io/) and shared them via [Azure Compute Gallery](https://docs.microsoft.com/en-us/azure/virtual-machines/shared-image-galleries).

See the [workflow file](.github/workflows/build_images.yml) to see how images are built and deployed.

## Images

[![Build Images](/../../actions/workflows/build_images.yml/badge.svg)](/../../actions/workflows/build_images.yml)

| Name      | OS                             | Additional Software                                          |
| --------- | ------------------------------ | -------------------------------------------------------------|
| VS2022Box | [Windows 11 Enterprise][win11] | [Visual Studio 2022](https://visualstudio.microsoft.com/vs/) |
| VSCodeBox | [Windows 11 Enterprise][win11] |                                                              |

Use [this form](/../../issues/new?assignees=colbylwilliams&labels=image&template=request_image.yml&title=%5BImage%5D%3A+) to request a new image.

### Preinstalled Software

The following software is installed on all images. Use [this form](/../../issues/new?assignees=colbylwilliams&labels=software&template=request_software.yml&title=%5BSoftware%5D%3A+) to request additional software.

- [Microsoft 365 Apps](https://www.microsoft.com/en-us/microsoft-365/products-apps-services)
- [Visual Studio Code](https://code.visualstudio.com/)
- [Google Chrome](https://www.google.com/chrome/)
- [Firefox](https://www.mozilla.org/en-US/firefox/new/)
- [GitHub Desktop](https://desktop.github.com/)
- [Postman](https://www.postman.com/)
- [Chocolatey](https://chocolatey.org/)
- [.Net](https://dotnet.microsoft.com/en-us/) (versions 3.1, 5.0, 6.0, 7.0)
- [Python](https://www.python.org/) (version 3.10.5)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/what-is-azure-cli) (2.37.0)

---

# Usage

To get started, [fork][fork] this repository.

_NOTE: The workflow that builds and publishes the images [is only triggered](.github/workflows/build_images.yml#L8-L10) if files the `/images` or `/scripts` folders change.  After completing the steps below, modify any file within those two folders (like changing the `version` in the `image.yml` files) to initiate a build._

## Azure Compute Gallery

Open the [`gallery.yml`](gallery.yml) file in the root of the repository and update following properties to match your [Azure Compute Gallery][az-gallery]:

- [`name`](gallery.yml#L1) - the name of your Azure Compute Gallery
- [`resourceGroup`](gallery.yml#L2) - The resource group that contains your Azure Compute Gallery

Example:

```yaml
name: MyGallery
resourceGroup: MyGallery-RG
```

## Service Principal

The solution requires a Service Principal to provision resources associated with create a new image (VMs, etc.).  See the [Azure Login action docs](create-sp) for instructions on how to create.

**IMPORTANT: Once you create a new Service Principal you must [assign it the following roles in RBAC][assign-rbac]:**:

- **Contributor** on the subscription used to provision resources, **OR**
- **Owner** on a specific (existing) resource group (see [Resource Group Usage](#resource-group-usage) below) and **Contributor** on the [Azure Compute Gallery][az-gallery] (and its resource group)

### `AZURE_CREDENTIALS`

In your fork create a new [repository secret](repo-secret) named `AZURE_CREDENTIALS` with a value that contains credentials for the service principal created above. For details on how to create these credentials, see the [Azure Login action docs](create-sp).

Example:

```sh
az ad sp create-for-rbac --sdk-auth --role contributor --scopes /subscriptions/<GUID> -n MyUniqueName
```

output:

```json
{
  "clientId": "<GUID>",
  "clientSecret": "<STRING>",
  "subscriptionId": "<GUID>",
  "tenantId": "<GUID>"
  (...)
}
```

**IMPORTANT: when pasting in the value for `AZURE_CREDENTIALS`, remove all line breaks so that the JSON is on a single line. Otherwise GitHub will assume subscriptionId and tenantId are secrets and prevent them from being share across workflow jobs.**

Example:

```json
{ "clientId": "<GUID>", "clientSecret": "<GUID>", "subscriptionId": "<GUID>", "tenantId": "<GUID>", (...) }
```

## Resource Group Usage

This solution uses Packer's [Azure builder][az-builder] which can either provision resources into a new resource group that it controls (default) or an existing one. The advantage of using a packer defined resource group is that failed resource cleanup is easier because you can simply remove the entire resource group, however this means that the provided credentials must have permission to create and remove resource groups. By using an existing resource group you can scope the provided credentials to just this group, however failed builds are more likely to leave unused artifacts.

To use an existing resource group you **must** provide a value for `buildResourceGroup` in the images `image.yml` file.

# Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit <https://cla.opensource.microsoft.com>.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

[win11]:https://www.microsoft.com/en-us/microsoft-365/windows/windows-11-enterprise
[dtl]:https://www.packer.io/plugins/provisioners/azure
[fork]:https://docs.github.com/en/get-started/quickstart/fork-a-repo
[az-builder]:https://www.packer.io/plugins/builders/azure/arm
[az-gallery]:https://docs.microsoft.com/en-us/azure/virtual-machines/shared-image-galleries?tabs=azure-cli
[create-sp]:https://github.com/Azure/login#configure-deployment-credentials
[repo-secret]:https://docs.github.com/en/actions/reference/encrypted-secrets#creating-encrypted-secrets-for-a-repository
[assign-rbac]:https://docs.microsoft.com/en-us/azure/role-based-access-control/role-assignments-portal?tabs=current
