# Dev Box Images

This repo contains custom images to be used with [Microsoft Dev Box](https://techcommunity.microsoft.com/t5/azure-developer-community-blog/introducing-microsoft-dev-box/ba-p/3412063).  It demonstrates how to create custom images with pre-installed software using [Packer](https://www.packer.io/) and shared them via [Azure Compute Gallery](https://docs.microsoft.com/en-us/azure/virtual-machines/shared-image-galleries).

See the [workflow file](https://github.com/colbylwilliams/devbox-images/blob/main/.github/workflows/build_images.yml) to see how images are built and deployed.

<sub>:heart: Thanks to @markusheiliger for [doing most the work](https://github.com/markusheiliger/devbox-factory).</sub>

## Images

[![Build Images](https://github.com/colbylwilliams/devbox-images/actions/workflows/build_images.yml/badge.svg)](https://github.com/colbylwilliams/devbox-images/actions/workflows/build_images.yml)

| Name      | OS                    | Preinstalled Software                                                                            |
| --------- | --------------------- | ------------------------------------------------------------------------------------------------ |
| VS2022Box | Windows 11 Enterprise | M365 Apps, GitHub Desktop, VS Code, VS 2022, Chocolatey, Postman, Google Chrome, Firefox, dotnet |
| VSCodeBox | Windows 11 Enterprise | M365 Apps, GitHub Desktop, VS Code, Chocolatey, Postman, Google Chrome, Firefox, dotnet          |
