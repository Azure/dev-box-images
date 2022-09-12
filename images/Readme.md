# Image definitions
Each folder contains the information to create a vm where the image will be created from.
## Key files necessary in each folder
- image.yml
    - The metadata for the image.
- image.bicep
    - The bicep file that defines how the vm is created and contains information on the [customizations](\scripts) being installed.

## Current image
- VS2022
    - Powershell modules
    - Azure Powershell module
    - Chocolatey
    - Chaco
    - Git
    - Github cli
    - DotNet
    - Python
    - Github desktop
    - VSCode
    - Azure cli
    - Visual studio 2022
- VSCodeBox
    - Powershell modules
    - Azure Powershell module
    - Chocolatey
    - Chaco
    - Git
    - Github cli
    - DotNet
    - Python
    - Github desktop
    - VSCode
    - Azure cli