#!/bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync