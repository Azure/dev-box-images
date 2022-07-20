# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Set TLS1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor "Tls12"

Write-Host "Installing AZ PowerShell module..."
Install-Module -Name Az -Scope AllUsers -SkipPublisherCheck -Force
