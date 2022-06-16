# Dev Box Images

This repo contains custom images to be used with [Microsoft Dev Box](https://techcommunity.microsoft.com/t5/azure-developer-community-blog/introducing-microsoft-dev-box/ba-p/3412063).  It demonstrates how to create custom images with pre-installed software using [Packer](https://www.packer.io/) and shared them via [Azure Compute Gallery](https://docs.microsoft.com/en-us/azure/virtual-machines/shared-image-galleries).

See the [workflow file](https://github.com/colbylwilliams/devbox-images/blob/main/.github/workflows/build_images.yml) to see how images are built and deployed.

<sub>:heart: Thanks to @markusheiliger for [doing most the work](https://github.com/markusheiliger/devbox-factory).</sub>

## Images

[![Build Images](https://github.com/colbylwilliams/devbox-images/actions/workflows/build_images.yml/badge.svg)](https://github.com/colbylwilliams/devbox-images/actions/workflows/build_images.yml)

| Name      | OS                             | Additional Software                                          |
| --------- | ------------------------------ | -------------------------------------------------------------|
| VS2022Box | [Windows 11 Enterprise][win11] | [Visual Studio 2022](https://visualstudio.microsoft.com/vs/) |
| VSCodeBox | [Windows 11 Enterprise][win11] |                                                              |

### Preinstalled Software

The following software is installed on all images:

- [Microsoft 365 Apps](https://www.microsoft.com/en-us/microsoft-365/products-apps-services)
- [Visual Studio Code](https://code.visualstudio.com/)
- [Google Chrome](https://www.google.com/chrome/)
- [Firefox](https://www.mozilla.org/en-US/firefox/new/)
- [GitHub Desktop](https://desktop.github.com/)
- [Postman](https://www.postman.com/)
- [Chocolatey](https://chocolatey.org/)
- [.Net](https://dotnet.microsoft.com/en-us/) (versions 3.1, 5.0, 6.0, 7.0)
- [Python](https://www.python.org/) (version 3.10.5)

[win11]:https://www.microsoft.com/en-us/microsoft-365/windows/windows-11-enterprise
