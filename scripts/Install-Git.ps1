# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

choco install git -y --installargs="/VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /o:PathOption=CmdTools /o:BashTerminalOption=ConHost /o:EnableSymlinks=Enabled /COMPONENTS=gitlfs" --no-progress

$currentPath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
$newPath = "C:\Program Files\Git\bin" + ';' + $currentPath
[System.Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")

# Add well-known SSH host keys to ssh_known_hosts
ssh-keyscan -t rsa,ecdsa,ed25519 github.com >> "C:\Program Files\Git\etc\ssh\ssh_known_hosts"
ssh-keyscan -t rsa ssh.dev.azure.com >> "C:\Program Files\Git\etc\ssh\ssh_known_hosts"
