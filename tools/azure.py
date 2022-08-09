import asyncio
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

RESOURCE_NOT_FOUND = 'Code: ResourceNotFound'

default_params = [
    'name',
    'location',
    'version',
    'tempResourceGroup',
    'buildResourceGroup',
    'gallery',
    'replicaLocations'
]

is_github = os.environ.get('GITHUB_ACTIONS', False)


def log_message(msg):
    print(f'[tools/azure] {msg}')


def log_warning(msg):
    if is_github:
        print(f'::warning:: {msg}')
    else:
        log_message(f'WARNING: {msg}')


def log_error(msg):
    if is_github:
        print(f'::error:: {msg}')
    else:
        log_message(f'ERROR: {msg}')

    raise ValueError(msg)


def _parse_command(command):
    if isinstance(command, list):
        args = command
    elif isinstance(command, str):
        args = command.split()
    else:
        raise ValueError(f'command must be a string or list, not {type(command)}')

    az = shutil.which('az')

    if args[0] == 'az':
        args.pop(0)

    if args[0] != az:
        args = [az] + args

    return args


def save_params_file(image, sub=None):
    sub = sub if sub else get_sub()

    params = {
        '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#',
        'contentVersion': '1.0.0.0',
        'parameters': {}
    }

    for v in default_params:
        if v in image and image[v]:
            params['parameters'][v] = {
                'value': image[v]
            }

    with open(Path(image['path']) / 'image.parameters.json', 'w') as f:
        json.dump(params, f, ensure_ascii=False, indent=4, sort_keys=True)


def save_params_files(images):
    sub = get_sub()

    for image in images:
        save_params_file(image, sub)


def cli(command):
    args = _parse_command(command)

    try:
        log_message(f'Running az cli command: {" ".join(args)}')
        proc = subprocess.run(args, capture_output=True, check=True, text=True)
        if proc.returncode == 0 and not proc.stdout:
            return None
        resource = json.loads(proc.stdout)
        return resource

    except subprocess.CalledProcessError as e:

        if e.stderr and RESOURCE_NOT_FOUND in e.stderr:
            return None

        sys.exit(e.stderr if e.stderr else 'azure cli command failed')

    except json.decoder.JSONDecodeError:
        sys.exit('{}: {}'.format('Could decode response json', proc.stderr if proc.stderr else proc.stdout if proc.stdout else proc))


async def cli_async(command):

    args = _parse_command(command)

    log_message(f'Running az cli command: {" ".join(args)}')
    proc = await asyncio.create_subprocess_exec(*args, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE)
    stdout, stderr = await proc.communicate()

    if stderr and RESOURCE_NOT_FOUND in stderr.decode():
        return None

    if proc.returncode != 0:
        sys.exit(stderr.decode() if stderr else 'azure cli command failed')

    if stdout:
        try:
            resource = json.loads(stdout)
            return resource
        except json.decoder.JSONDecodeError:
            sys.exit('{}: {}'.format('Could decode response json', stderr.decode() if stderr else stdout if stdout else proc))


def get_sub():
    sub = cli('az account show')
    return sub['id']


async def get_sub_async():
    sub = await cli_async('az account show')
    return sub['id']


def _img_def_show_cmd(image):
    return [
        'sig', 'image-definition', 'show',
        '--only-show-errors',
        '-g', image['gallery']['resourceGroup'],
        '-r', image['gallery']['name'],
        '-i', image['name']
    ]


def _img_ver_show_cmd(image):
    return [
        'sig', 'image-version', 'show',
        '--only-show-errors',
        '-g', image['gallery']['resourceGroup'],
        '-r', image['gallery']['name'],
        '-i', image['name'],
        '-e', image['version']
    ]


def _img_def_create_cmd(image):
    return [
        'sig', 'image-definition', 'create',
        '--only-show-errors',
        '-g', image['gallery']['resourceGroup'],
        '-r', image['gallery']['name'],
        '-i', image['name'],
        '-p', image['publisher'],
        '-f', image['offer'],
        '-s', image['sku'],
        '--os-type', image['os'],
        # '--os-state', 'Generalized', (default)
        '--description', image['description'],
        '--hyper-v-generation', 'V2',
        '--features', 'SecurityType=TrustedLaunch'
    ]


def ensure_image_def_version(image):

    image_name = image['name']
    image_version = image['version']

    build = False

    log_message(f'Validating image definition and version for {image_name}')
    log_message(f'Checking if image definition exists for {image_name}')
    imgdef = cli(_img_def_show_cmd(image))

    if imgdef:  # image definition exists, check if the version already exists

        log_message(f'Found existing image definition for {image_name}')
        log_message(f'Checking if image version {image_version} exists for {image_name}')
        imgver = cli(_img_ver_show_cmd(image))

        if imgver:
            log_message(f'Found existing image version {image_version} for {image_name}')
            log_warning(f'{image_name} was not built because version {image_version} already exists. Please update the version number or delete the existing image version and try again.')
        else:  # image version does not exist, add it to the list of images to create
            log_message(f'Image version {image_version} does not exist for {image_name}')
            build = True

    else:  # image definition does not exist, create it and skip the version check

        log_message(f'Image definition does not exist for {image_name}')
        log_message(f'Creating image definition for {image_name}')
        imgdef = cli(_img_def_create_cmd(image))

        build = True

    return build, imgdef


async def ensure_image_def_version_async(image):

    image_name = image['name']
    image_version = image['version']

    build = False

    log_message(f'Validating image definition and version for {image_name}')
    log_message(f'Checking if image definition exists for {image_name}')
    imgdef = await cli_async(_img_def_show_cmd(image))

    if imgdef:  # image definition exists, check if the version already exists

        log_message(f'Found existing image definition for {image_name}')
        log_message(f'Checking if image version {image_version} exists for {image_name}')
        imgver = await cli_async(_img_ver_show_cmd(image))

        if imgver:
            log_message(f'Found existing image version {image_version} for {image_name}')
            log_warning(f'{image_name} was not built because version {image_version} already exists. Please update the version number or delete the existing image version and try again.')
        else:  # image version does not exist, add it to the list of images to create
            log_message(f'Image version {image_version} does not exist for {image_name}')
            build = True

    else:  # image definition does not exist, create it and skip the version check

        log_message(f'Image definition does not exist for {image_name}')
        log_message(f'Creating image definition for {image_name}')
        imgdef = await cli_async(_img_def_create_cmd(image))

        build = True

    return build, imgdef
