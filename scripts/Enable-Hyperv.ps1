# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Stop script execution when a non-terminating error occurs
$ErrorActionPreference = "Stop"

Write-Output "Enable Hyper-V ."
# Use the -NoRestart, the restart will happen in the packer file.  Having the feature restart the machine leads to inconsistent behavior.
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart
Write-Output "Restart for Hyper-V required in Packer file."