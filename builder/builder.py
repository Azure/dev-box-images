# ------------------------------------
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
# ------------------------------------

import os
import sys
from datetime import datetime, timezone
from pathlib import Path

import azure as az
import image as img
import loggers
import packer

# indicates if the script is running in the docker container
in_builder = os.environ.get('ACI_IMAGE_BUILDER', False)
in_builder = True if in_builder else False

builder_version = os.environ.get('ACI_IMAGE_BUILDER_VERSION', 'unknown')

log = loggers.getLogger(__name__)


log.info(f'ACI_IMAGE_BUILDER: {in_builder}')
log.info(f'ACI_IMAGE_BUILDER_VERSION: {builder_version}')
log.debug(f'in_builder: {in_builder}')


if not in_builder:
    log.warning('Running outside of the builder container. This should only be done during testing.')


def error_exit(message):
    log.error(message)
    sys.exit(message)


repo = Path('/mnt/repo') if in_builder else Path(__file__).resolve().parent.parent
storage = Path('/mnt/storage') if in_builder else repo / '.local' / 'storage'

log.info(f'Repository path: {repo}')
log.info(f'Storage path: {storage}')

if not os.path.isdir(repo):
    error_exit(f'Missing volume {repo}')

if not os.path.isdir(storage):
    log.warning(f'Missing volume {storage}')

for env in ['BUILD_IMAGE_NAME']:
    if not os.environ.get(env, False):
        error_exit(f'Missing {env} environment variable')

image_name = os.environ['BUILD_IMAGE_NAME']
image_path = repo / 'images' / image_name

log.info(f'Image name: {image_name}')
log.info(f'Image path: {image_path}')

suffix = datetime.now(timezone.utc).strftime('%Y%m%d%H%M%S')
log.info(f'Build Suffix: {suffix}')

if in_builder:
    az_client_id = os.environ.get('AZURE_CLIENT_ID', None)
    az_client_secret = os.environ.get('AZURE_CLIENT_SECRET', None)
    az_tenant_id = os.environ.get('AZURE_TENANT_ID', None)

    if az_client_id and az_client_secret and az_tenant_id:
        log.info(f'Found credentials for Azure Service Principal')
        log.info(f'Logging in with Service Principal')
        az.cli(f'az login --service-principal -u {az_client_id} -p {az_client_secret} -t {az_tenant_id} --allow-no-subscriptions', log_command=False)
    else:
        log.info(f'No credentials for Azure Service Principal')
        log.info(f'Logging in to Azure with managed identity')
        az.cli('az login --identity --allow-no-subscriptions')

gallery = img.get_gallery()
common = img.get_common()

image = img.get(image_name, gallery, common, suffix, ensure_azure=True)

skip_build = not in_builder

if image['build']:
    packer.save_vars_file(image)

    if not skip_build:
        packer.execute(image)

if skip_build:
    log.warning('Skipping build execution because --skip-build was provided')
