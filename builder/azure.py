# ------------------------------------
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
# ------------------------------------

import asyncio
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

import loggers

IMAGE_PARAMS_FILE = 'image.parameters.json'
RESOURCE_NOT_FOUND = 'Code: ResourceNotFound'
DEFAULT_PARAMS = ['name', 'location', 'version', 'tempResourceGroup', 'buildResourceGroup', 'gallery', 'replicaLocations']

log = loggers.getLogger(__name__)


def error_exit(message):
    log.error(message)
    sys.exit(message)


def _img_def_show_cmd(image):
    return ['sig', 'image-definition', 'show', '--only-show-errors', '-g', image['gallery']['resourceGroup'],
            '-r', image['gallery']['name'], '-i', image['name'], '--subscription', image['gallery']['subscription']]


def _img_ver_show_cmd(image):
    return ['sig', 'image-version', 'show', '--only-show-errors', '-g', image['gallery']['resourceGroup'],
            '-r', image['gallery']['name'], '-i', image['name'], '-e', image['version'], '--subscription', image['gallery']['subscription']]


def _img_def_create_cmd(image):
    return ['sig', 'image-definition', 'create', '--only-show-errors', '-g', image['gallery']['resourceGroup'],
            '-r', image['gallery']['name'], '-i', image['name'], '-p', image['publisher'], '-f', image['offer'],
            '-s', image['sku'], '--os-type', image['os'], '--description', image['description'],
            '--hyper-v-generation', 'V2', '--features', 'SecurityType=TrustedLaunch', '--subscription', image['gallery']['subscription']]


def _img_builder_cmd(image, command):
    return ['image', 'builder', command, '-g', image['gallery']['resourceGroup'], '-n', image['name'], '--subscription', image['gallery']['subscription']]


def _img_builder_deploy_cmd(image):
    bicep_file = os.path.join(image['path'], 'image.bicep')
    params_file = '@' + os.path.join(image['path'], IMAGE_PARAMS_FILE)
    return ['deployment', 'group', 'create', '-n', image['name'], '-g', image['gallery']['resourceGroup'],
            '-f', bicep_file, '-p', params_file, '--no-prompt', '--subscription', image['gallery']['subscription']]


def _parse_command(command):
    if isinstance(command, list):
        args = command
    elif isinstance(command, str):
        args = command.split()
    else:
        raise ValueError(f'az command must be a string or list, not {type(command)}')

    az = shutil.which('az')

    if args[0] == 'az':
        args.pop(0)

    if args[0] != az:
        args = [az] + args

    return args


def cli(command, log_command=True):
    args = _parse_command(command)

    try:
        if log_command:
            log.info(f'Running az cli command: {" ".join(args)}')

        proc = subprocess.run(args, capture_output=True, check=True, text=True)

        if proc.returncode == 0 and not proc.stdout:
            return None
        for line in proc.stdout.splitlines():
            log.info(line)

        resource = json.loads(proc.stdout)
        return resource

    except subprocess.CalledProcessError as e:

        if e.stderr and RESOURCE_NOT_FOUND in e.stderr:
            return None

        error_exit(e.stderr if e.stderr else 'azure cli command failed')

    except json.decoder.JSONDecodeError:
        error_exit('{}: {}'.format('Could not decode response json', proc.stderr if proc.stderr else proc.stdout if proc.stdout else proc))


async def cli_async(command, log_command=True):
    args = _parse_command(command)

    if log_command:
        log.info(f'Running az cli command: {" ".join(args)}')

    try:
        proc = await asyncio.create_subprocess_exec(*args, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE)
        stdout, stderr = await proc.communicate()

        if stderr and RESOURCE_NOT_FOUND in stderr.decode():
            return None

        if proc.returncode != 0:
            error_exit(stderr.decode() if stderr else 'azure cli command failed')

        if stdout:
            for line in stdout.decode().splitlines():
                log.info(line)

            try:
                resource = json.loads(stdout)
                return resource
            except json.decoder.JSONDecodeError:
                error_exit('{}: {}'.format('Could not decode response json', stderr.decode() if stderr else stdout if stdout else proc))

    except SystemExit as e:

        error_exit(e.code if e.code else 'azure cli command failed')


def get_sub():
    sub = cli('az account show')
    return sub['id']


async def get_sub_async():
    sub = await cli_async('az account show')
    return sub['id']


def ensure_image_def_version(image):

    image_name = image['name']
    image_version = image['version']

    build = False

    log.info(f'Validating image definition and version for {image_name}')
    log.info(f'Checking if image definition exists for {image_name}')
    imgdef = cli(_img_def_show_cmd(image))

    if imgdef:  # image definition exists, check if the version already exists

        log.info(f'Found existing image definition for {image_name}')
        log.info(f'Checking if image version {image_version} exists for {image_name}')
        imgver = cli(_img_ver_show_cmd(image))

        if imgver:
            log.info(f'Found existing image version {image_version} for {image_name}')
            log.warning(f'{image_name} was not built because version {image_version} already exists. Please update the version number or delete the existing image version and try again.')
        else:  # image version does not exist, add it to the list of images to create
            log.info(f'Image version {image_version} does not exist for {image_name}')
            build = True

    else:  # image definition does not exist, create it and skip the version check

        log.info(f'Image definition does not exist for {image_name}')
        log.info(f'Creating image definition for {image_name}')
        imgdef = cli(_img_def_create_cmd(image))

        build = True

    return build, imgdef


async def ensure_image_def_version_async(image):

    image_name = image['name']
    image_version = image['version']

    build = False

    log.info(f'Validating image definition and version for {image_name}')
    log.info(f'Checking if image definition exists for {image_name}')
    imgdef = await cli_async(_img_def_show_cmd(image))

    if imgdef:  # image definition exists, check if the version already exists

        log.info(f'Found existing image definition for {image_name}')
        log.info(f'Checking if image version {image_version} exists for {image_name}')
        imgver = await cli_async(_img_ver_show_cmd(image))

        if imgver:
            log.info(f'Found existing image version {image_version} for {image_name}')
            log.warning(f'{image_name} was not built because version {image_version} already exists. Please update the version number or delete the existing image version and try again.')
        else:  # image version does not exist, add it to the list of images to create
            log.info(f'Image version {image_version} does not exist for {image_name}')
            build = True

    else:  # image definition does not exist, create it and skip the version check

        log.info(f'Image definition does not exist for {image_name}')
        log.info(f'Creating image definition for {image_name}')
        imgdef = await cli_async(_img_def_create_cmd(image))

        build = True

    return build, imgdef


def create_run_template(image):
    existing = cli(_img_builder_cmd(image, 'show'))
    if existing:
        log.warning(f'image template {image["name"]} already exists in {image["gallery"]["resourceGroup"]}. deleting')
        cli(_img_builder_cmd(image, 'delete'))

    log.info(f'Creating image template for {image["name"]}')
    group = cli(_img_builder_deploy_cmd(image))

    log.info(f'Executing build on image template: {image["name"]}')
    build = cli(_img_builder_cmd(image, 'run'))

    return group, build


async def create_run_template_async(image):
    existing = await cli_async(_img_builder_cmd(image, 'show'))
    if existing:
        log.warning(f'image template {image["name"]} already exists in {image["gallery"]["resourceGroup"]}. deleting')
        await cli_async(_img_builder_cmd(image, 'delete'))

    log.info(f'Creating image template for {image["name"]}')
    group = await cli_async(_img_builder_deploy_cmd(image))

    log.info(f'Executing build on image template: {image["name"]}')
    build = await cli_async(_img_builder_cmd(image, 'run'))

    return group, build


def save_params_file(image):
    params = {
        '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#',
        'contentVersion': '1.0.0.0',
        'parameters': {}
    }

    for v in DEFAULT_PARAMS:
        if v in image and image[v]:
            params['parameters'][v] = {
                'value': image[v]
            }

    with open(Path(image['path']) / IMAGE_PARAMS_FILE, 'w') as f:
        json.dump(params, f, ensure_ascii=False, indent=4, sort_keys=True)


def save_params_files(images):
    for image in images:
        save_params_file(image)
