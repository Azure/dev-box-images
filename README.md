# Dev Box Images

This repo contains custom images to be used with [Microsoft Dev Box](https://techcommunity.microsoft.com/t5/azure-developer-community-blog/introducing-microsoft-dev-box/ba-p/3412063).  It demonstrates how to create custom images with pre-installed software using [Packer](https://www.packer.io/) and shared them via [Azure Compute Gallery](https://docs.microsoft.com/en-us/azure/virtual-machines/shared-image-galleries).

See the [workflow file](https://github.com/Azure/dev-box-images/blob/main/.github/workflows/build_images.yml) to see how images are built and deployed.

## Images

[![Build Images](https://github.com/Azure/dev-box-images/actions/workflows/build_images.yml/badge.svg)](https://github.com/Azure/dev-box-images/actions/workflows/build_images.yml)

| Name      | OS                             | Additional Software                                          |
| --------- | ------------------------------ | -------------------------------------------------------------|
| VS2022Box | [Windows 11 Enterprise][win11] | [Visual Studio 2022](https://visualstudio.microsoft.com/vs/) |
| VSCodeBox | [Windows 11 Enterprise][win11] |                                                              |

Use [this form](https://github.com/Azure/dev-box-images/issues/new?assignees=colbylwilliams&labels=image&template=request_image.yml&title=%5BImage%5D%3A+) to request a new image.

### Preinstalled Software

The following software is installed on all images. Use [this form](https://github.com/Azure/dev-box-images/issues/new?assignees=colbylwilliams&labels=software&template=request_software.yml&title=%5BSoftware%5D%3A+) to request additional software.

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

## Usage

To get started:

1. Fork this repository
2. In your fork create a new [repository secret](https://docs.github.com/en/actions/reference/encrypted-secrets#creating-encrypted-secrets-for-a-repository) named `AZURE_CREDENTIALS` with a value that contains credentials for a service principal with appropriate permissions to create resource groups and deploy images to an [Azure Compute Gallery](https://docs.microsoft.com/en-us/azure/virtual-machines/shared-image-galleries?tabs=azure-cli). For details on how to create these credentials, see the [Azure Login action docs](https://github.com/Azure/login#configure-deployment-credentials).
3. Open the `build_images.yml` file and update the environment variables: [`galleryName`](https://github.com/Azure/dev-box-images/blob/main/.github/workflows/build_images.yml#L4) and [`resourceGroup`](https://github.com/Azure/dev-box-images/blob/main/.github/workflows/build_images.yml#L5) to match your Azure Compute Gallery.

## Contributing

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
