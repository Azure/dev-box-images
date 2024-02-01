# Templates

The [templates](templates) folder contains bicep templates that can be used to deploy DevCenter/Dev Box and Azure Compute Gallery resources.

| Template[^sub] | Description |
| -------------- | ----------- |
| [devcenter.bicep](#devcenterbicep) | Creates a new DevCenter and optionally attaches an Azure Compute Gallery and applies the appropriate permissions to allow access to the Gallery by the DevCenter and Windows 365 |
| [project.bicep](#projectbicep) | Creates a new Project and optionally assigns the appropriate permissions to Project Admins and Dev Box Users |
| [gallery.bicep](#gallerybicep) | Creates a new Azure Compute Gallery and applies the appropriate permissions to allow access by Windows 365 and optionally a DevCenter and/or an additional identity that can be used with CI |
| [devboxDefinition.bicep](#devboxdefinitionbicep) | Creates a new Dev Box Definition based on a gallery image in a DevCenter |
| [networkConnection.bicep](#networkconnectionbicep) | Creates a new Network Connection and optionally attaches it to a DevCenter |
| [pool.bicep](#poolbicep) | Creates a new Dev Box Pool for a Project |
| [galleryAttach.bicep \*](#galleryattachbicep) | Attaches an Azure Compute Gallery to a DevCenter so the Gallery's images can be used to create Dev Box Definitions |
| [galleryRole.bicep \*](#galleryrolebicep) | Assigns the Reader, Contributor, or Owner role on a Azure Compute Gallery to a Service Principal |
| [networkAttach.bicep \*](#networkattachbicep) | Attaches a Network Connection to a DevCenter so it can be used when creating Dev Box Pools  |
| [projectRole.bicep \*](#projectrolebicep) | Assigns the DevCenter Project Admin or DevCenter Dev Box User role on a Project to a user |
| [vnet.bicep](#vnetbicep) | Creates a new "vanilla" VNet (this template is not currently used and is provided to simplify the setup of Test environments) |

----

## [devcenter.bicep](devcenter.bicep)

#### Summary

Creates a new DevCenter and optionally attaches an Azure Compute Gallery and applies the appropriate permissions to allow access to the Gallery by the DevCenter and Windows 365

#### Parameters

| Parameter | Required | Type | Description |
| --------- | -------- | ---- | ----------- |
| location | False | string | Location of the Dev Center. If none is provided, the resource group location is used. |
| name | True | string | Name of the Dev Center |
| galleryId | False | string | Resource ID of an existing Azure Compute Gallery to attach to the Dev Center. |
| tags | False | object | Tags to apply to the resources |

#### Example

```sh
az deployment group create -g RG-Dev -f devcenter.bicep -p name=MyDevCener
```

## [project.bicep](project.bicep)

#### Summary

Creates a new Project and optionally assigns the appropriate permissions to Project Admins and Dev Box Users

#### Parameters

| Parameter | Required | Type | Description |
| --------- | -------- | ---- | ----------- |
| location | False | string | Location of the Dev Center. If none is provided, the resource group location is used. |
| name | True | string | Name of the Project |
| devCenterId | True | string | The Resource ID of the DevCenter. |
| description | False | string | The description of the Project. |
| projectAdmins | False | array | The principal ids of users to assign the role of DevCenter Project Admin.  Users must either have DevCenter Project Admin or DevCenter Dev Box User role in order to create a Dev Box. |
| devBoxUsers | False | array | The principal ids of users to assign the role of DevCenter Dev Box User.  Users must either have DevCenter Project Admin or DevCenter Dev Box User role in order to create a Dev Box. |
| tags | False | object | Tags to apply to the resources |

#### Example

```sh
az deployment group create -g RG-Dev -f project.bicep -p name=MyProj devCenterId=/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/RG-Dev/providers/Microsoft.DevCenter/devcenters/MyDevCenter
```

## [gallery.bicep](gallery.bicep)

#### Summary

Creates a new Azure Compute Gallery and applies the appropriate permissions to allow access by Windows 365 and optionally a DevCenter and/or an additional identity that can be used with CI

#### Parameters

| Parameter | Required | Type | Description |
| --------- | -------- | ---- | ----------- |
| location | False | string | Location of the Dev Center. If none is provided, the resource group location is used. |
| name | True | string| Name of the Azure Compute Gallery |
| devCenterId | False | string| The Resource ID of the DevCenter. If provided the new Gallery will be attached to the DevCenter |
| builderPrincipalId | False | string | The principal id of a service principal used in the image build pipeline. If provided the service principal will be given Owner permissions on the gallery |
| tags | False | object | Tags to apply to the resources |

#### Example

```sh
az deployment group create -g RG-Gallery -f gallery.bicep -p name=MyGallery devCenterId=/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/RG-Dev/providers/Microsoft.DevCenter/devcenters/MyDevCenter
```

## [devboxDefinition.bicep](devboxDefinition.bicep)

#### Summary

Creates a new Dev Box Definition based on a gallery image in a DevCenter

#### Parameters

| Parameter | Required | Type | Description |
| --------- | -------- | ---- | ----------- |
| location | False | string | Location for the Dev Box Definition. If none is provided, the resource group location is used. |
| name | True | string | Dev Box Definition name |
| devCenterName | True | string | The resource ID of the DevCenter. |
| galleryName | True | string | The name of the gallery. |
| imageName | True | string | The name of the image in the gallery to use. |
| imageVersion | False | string | The version of the image to use. If none is provided, the latest version will be used. |
| storage | False | string | The storage in GB used for the Operating System disk of Dev Boxes created using this definition. |
| compute | False | string | The specs on the of Dev Boxes created using this definition. For example 8c32gb would create dev boxes with 8 vCPUs and 32 GB RAM. |
| tags | False | object | Tags to apply to the resources |

#### Example

```sh
az deployment group create -g RG-Dev -f devboxDefinition.bicep -p name=VSCodeBox devCenterName=MyDevCenter galleryName=MyGallery imageName=VSCodeBox
```

## [networkConnection.bicep](networkConnection.bicep)

#### Summary

Creates a new Network Connection and optionally attaches it to a DevCenter

#### Parameters

| Parameter | Required | Type | Description |
| --------- | -------- | ---- | ----------- |
| location | False | string | Location for the Network Connection. If none is provided, the resource group location is used. |
| name | True | string | Network connection name |
| vnetId | True | string | The resource ID of the VNet |
| subnet | False | string | Name of the subnet to use. If none is provided uses default |
| networkingResourceGroupName | False | string | Name of the resource group in which the NICs will be created. This should NOT be an existing resource group, it will be created by the service in the same subscription as your vnet. If not provided a name will automatically be generated based on the vnet name and region. |
| domainJoinType | False | string | Active Directory join type |
| devCenterId | False | string | The resource ID of an existing DevCenter. If provided, the network connection will be attached to the DevCenter |
| tags | False | object | Tags to apply to the resources |

#### Example

```sh
az deployment group create -g RG-Net -f networkConnection.bicep -p mame=MyNc vnetId=/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/RG-Net/providers/Microsoft.Network/virtualNetworks/MyVnet devCenterId=/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/RG-Dev/providers/Microsoft.DevCenter/devcenters/MyDevCenter
```

## [pool.bicep](pool.bicep)

#### Summary

Creates a new Dev Box Pool for a Project

#### Parameters

| Parameter | Required | Type | Description |
| --------- | -------- | ---- | ----------- |
| location | False | string | Location of the Pool. If none is provided, the resource group location is used. |
| name | True | string | Name of the Project |
| projectName | True | string | Name of the Project |
| devBoxDefinitionName | True | string | Name of a Dev Box definition in parent Project of this Pool |
| networkConnectionName | True | string | Name of a Network Connection in parent Project of this Pool |
| localAdministrator | False | string | Indicates whether owners of Dev Boxes in this pool are added as local administrators on the Dev Box. Default is Enabled |
| tags | False | object | Tags to apply to the resources |

#### Example

```sh
az deployment group create -g RG-Dev -f pool.bicep -p name=VSCodeBoxes projectName=MyProj devBoxDefinitionName=VSCodeBox networkConnectionName=MyNc
```

## [galleryAttach.bicep](galleryAttach.bicep)

#### Summary

Attaches an Azure Compute Gallery to a DevCenter so the Gallery's images can be used to create Dev Box Definitions

#### Parameters

| Parameter | Required | Type | Description |
| --------- | -------- | ---- | ----------- |
| name | False | string | Name of the Gallery in DevCenter. If not provided, the Compute Gallery name is used. |
| devCenterName | True | string | Name of the DevCenter. |
| galleryResourceId | True | string | The resource ID of the backing Azure Compute Gallery. |

#### Example

```sh
az deployment group create -g RG-Dev -f galleryAttach.bicep -p devCenterName=MyDevCenter galleryResourceId=/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/RG-Gallery/providers/Microsoft.Compute/galleries/MyGallery
```

## [galleryRole.bicep](galleryRole.bicep)

#### Summary

Assigns the Reader, Contributor, or Owner role on a Azure Compute Gallery to a Service Principal

#### Parameters

| Parameter | Required | Type | Description |
| --------- | -------- | ---- | ----------- |
| principalId | True | string | The principal id of the Service Principal to assign permissions to the Gallery. |
| galleryName | True | string | Name of an existing Azure Compute Gallery. |
| role | False | string | The Role to assign. Defaults to Reader |

#### Example

```sh
az deployment group create -g RG-Gallery -f galleryRole.bicep -p principalId=00000000-0000-0000-0000-000000000000 galleryName=MyGallery
```

## [networkAttach.bicep](networkAttach.bicep)

#### Summary

Attaches a Network Connection to a DevCenter so it can be used when creating Dev Box Pools

#### Parameters

| Parameter | Required | Type | Description |
| --------- | -------- | ---- | ----------- |
| name | False | string | Name of the attached Network Connection in DevCenter. If not provided, the Network Connection name is used. |
| devCenterName | True | string | Name of the DevCenter. |
| networkConnectionId | True | string | The resource ID of the Network Connection. |

#### Example

```sh
az deployment group create -g RG-Dev -f networkAttach.bicep -p devCenterName=MyDevCenter networkConnectionId=/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/RG-Net/providers/Microsoft.DevCenter/networkConnections/MyNc
```

## [projectRole.bicep](projectRole.bicep)

#### Summary

Assigns the DevCenter Project Admin or DevCenter Dev Box User Role on a Project to a user

#### Parameters

| Parameter | Required | Type | Description |
| --------- | -------- | ---- | ----------- |
| principalId | True | string | The principal id of the Service Principal to assign permissions to the Project. |
| projectName | True | string | The Project name. |
| role | False | string | The Role to assign. |
| principalType | False | string | The principal type of the assigned principal ID. |

#### Example

```sh
az deployment group create -g RG-Dev -f projectRole.bicep -p principalId=00000000-0000-0000-0000-000000000000 projectName=MyProj
```

## [vnet.bicep](vnet.bicep)

#### Summary

Creates a new "vanilla" VNet (this template is not currently used and is provided to simplify the setup of Test environments)

#### Parameters

| Parameter | Required | Type | Description |
| --------- | -------- | ---- | ----------- |
| location | False | string | Location of the VNet. If none is provided, the resource group location is used. |
| name | True | string | Name of the VNet |

#### Example

```sh
az deployment group create -g RG-Net -f vnet.bicep -p name=MyVnet
```

[^sub]: Templates with an asterisk (**\***) are referenced inside of the top-level templates, and normally aren't used directly.
