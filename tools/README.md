# Tools

This folder contains a collection of useful scripts and bicep templates for working with DevCenter and Dev Boxes.

## Templates

The [templates](templates) folder contains bicep templates that can be used to deploy DevCenter/Dev Box and Azure Compute Gallery resources.  See the [README](templates/README.md) in the [templates](templates) for details documentation on each template and example usage

| Template[^sub] | Description |
| -------------- | ----------- |
| [devcenter.bicep](templates/README.md#devcenterbicep) | Creates a new DevCenter and optionally attaches an Azure Compute Gallery and applies the appropriate permissions to allow access to the Gallery by the DevCenter and Windows 365 |
| [project.bicep](templates/README.md#projectbicep) | Creates a new Project and optionally assigns the appropriate permissions to Project Admins and Dev Box Users |
| [gallery.bicep](templates/README.md#gallerybicep) | Creates a new Azure Compute Gallery and applies the appropriate permissions to allow access by Windows 365 and optionally a DevCenter and/or an additional identity that can be used with CI |
| [devboxDefinition.bicep](templates/README.md#devboxdefinitionbicep) | Creates a new Dev Box Definition based on a gallery image in a DevCenter |
| [networkConnection.bicep](templates/README.md#networkconnectionbicep) | Creates a new Network Connection and optionally attaches it to a DevCenter |
| [pool.bicep](templates/README.md#poolbicep) | Creates a new Dev Box Pool for a Project |
| [galleryAttach.bicep \*](templates/README.md#galleryattachbicep) | Attaches an Azure Compute Gallery to a DevCenter so the Gallery's images can be used to create Dev Box Definitions |
| [galleryRole.bicep \*](templates/README.md#galleryrolebicep) | Assigns the Reader, Contributor, or Owner role on a Azure Compute Gallery to a Service Principal |
| [networkAttach.bicep \*](templates/README.md#networkattachbicep) | Attaches a Network Connection to a DevCenter so it can be used when creating Dev Box Pools  |
| [projectRole.bicep \*](templates/README.md#projectrolebicep) | Assigns the DevCenter Project Admin or DevCenter Dev Box User role on a Project to a user |
| [vnet.bicep](templates/README.md#vnetbicep) | Creates a new "vanilla" VNet (this template is not currently used and is provided to simplify the setup of Test environments) |

## Scripts

| Script | Description |
| -------------- | ----------- |
| [stop-boxes.py](#stop-boxespy) | Stops all Dev Boxes across projects in a DevCenter |
| [bump-version.py](#bump-versionpy) | Increments the version number in the image.yml files |

## [stop-boxes.py](stop-boxes.py)

#### Summary

Stops all (running) Dev Boxes across projects in a DevCenter. You can optionally specify specific Projects, Pools, or Users to filter which boxes to stop.

**Note: you must be logged in to the Azure CLI, and the script will only delete dev boxes in projects where you have DevCenter Project Admin role assignment.**

#### Arguments

| Argument | Required | Description |
| -------- | -------- | ----------- |
| --dev-center \| -dc | True | the devcenter to operate on |
| --projects \| -p | False | names of projects to stop running boxes. if not specified all projects will be included |
| --pools | False | names of pools to stop running boxes. if not specified all pools will be included |
| --users | False | ids of users to stop running boxes. if not specified all users will be included |

#### Examples

##### stop all boxes in a devcenter the patch version on all images

```sh
python ./stop-boxes.py -dc MyDevCenter
```

##### stop all boxes in a devcenter for ProjectA and ProjectB

```sh
python ./stop-boxes.py -dc MyDevCenter --projects ProjectA ProjectB
```

##### stop all boxes in a devcenter for user 00000000-0000-0000-0000-000000000000

```sh
python ./stop-boxes.py -dc MyDevCenter --users 00000000-0000-0000-0000-000000000000
```

## [bump-version.py](bump-version.py)

#### Summary

Increments the version number in the image.yml files

#### Arguments

| Argument | Required | Description |
| -------- | -------- | ----------- |
| --major | False | bump major version |
| --minor | False | bump minor version |
| --images | False | images to bump images version, all images if not specified |

#### Examples

##### bump the patch version on all images

```sh
python ./bump-version.py

# output:
# bumping version for VSCodeBox 1.0.3 -> 1.0.4
# bumping version for VS2022Box 1.0.3 -> 1.0.4
```

##### bump the minor version on VSCodeBox image

```sh
python ./bump-version.py --minor --images VSCodeBox

# output:
# bumping version for VSCodeBox 1.0.4 -> 1.1.0
```
