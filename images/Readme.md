# Image definitions
Each folder contains the information to create a vm where the image will be created from.
## Key files necessary in each folder
- image.yml
    - The metadata for the image.
- image.bicep
    - The bicep file that defines how the vm is created and contains information on the [customizations](\scripts) being installed.