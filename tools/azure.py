import asyncio
import json
import shutil
import subprocess
import sys

RESOURCE_NOT_FOUND = 'Code: ResourceNotFound'


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


def cli(command):
    args = _parse_command(command)

    try:
        proc = subprocess.run(args, capture_output=True, check=True, text=True)
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

    print(f'validating image definition and version for {image_name}')
    print(f'..checking if image definition exists for {image_name}')
    imgdef = cli(_img_def_show_cmd(image))

    if imgdef:  # image definition exists, check if the version already exists

        print(f'..found existing image definition for {image_name}')
        print(f'..checking if image version {image_version} exists for {image_name}')
        imgver = cli(_img_ver_show_cmd(image))

        if imgver:
            print(f'..found existing image version {image_version} for {image_name}')
            print(f'::warning:: {image_name} was not built because version {image_version} already exists. Please update the version number or delete the existing image version and try again.')
        else:  # image version does not exist, add it to the list of images to create
            print(f'..image version {image_version} does not exist for {image_name}')
            build = True

    else:  # image definition does not exist, create it and skip the version check

        print(f'..image definition does not exist for {image_name}')
        print(f'..creating image definition for {image_name}')
        imgdef = cli(_img_def_create_cmd(image))

        build = True

    return build, imgdef


async def ensure_image_def_version_async(image):

    image_name = image['name']
    image_version = image['version']

    build = False

    print(f'validating image definition and version for {image_name}')
    print(f'..checking if image definition exists for {image_name}')
    imgdef = await cli_async(_img_def_show_cmd(image))

    if imgdef:  # image definition exists, check if the version already exists

        print(f'..found existing image definition for {image_name}')
        print(f'..checking if image version {image_version} exists for {image_name}')
        imgver = await cli_async(_img_ver_show_cmd(image))

        if imgver:
            print(f'..found existing image version {image_version} for {image_name}')
            print(f'::warning:: {image_name} was not built because version {image_version} already exists. Please update the version number or delete the existing image version and try again.')
        else:  # image version does not exist, add it to the list of images to create
            print(f'..image version {image_version} does not exist for {image_name}')
            build = True

    else:  # image definition does not exist, create it and skip the version check

        print(f'..image definition does not exist for {image_name}')
        print(f'..creating image definition for {image_name}')
        imgdef = await cli_async(_img_def_create_cmd(image))

        build = True

    return build, imgdef
