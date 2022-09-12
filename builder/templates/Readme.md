# Infrastructure templates
These template are used to create the necessary resources for the custom image builder.  Use the following commands to deploy the .bicep files manually.

```azurecli
az login
az deployment group create --resource-group <resource-group-name> --template-file <path-to-bicep> --parameters <parameter-for-template>
```

## builder.bicep
Creates the container resource with the storage account and repo mounted as drives.

## builder_sandbox.bicep
Create the necessary resources for the supporting infrastructure. This includes: Virtual network with private connections to a Keyvault and storage