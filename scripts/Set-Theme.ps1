# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

$ProgressPreference = 'SilentlyContinue'	# hide any progress output

$process = Start-Process -FilePath "C:\Windows\Resources\Themes\dark.theme"; timeout /t 3; taskkill /im "systemsettings.exe" /f

exit $process.ExitCode