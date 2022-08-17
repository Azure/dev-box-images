import argparse
import asyncio
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

import azure as az
import gallery as gal
import image as img
import loggers
import repos

BUILDER_PARAMS_FILE = 'builder.parameters.json'

log = loggers.getLogger(__name__)


def error_exit(message):
    log.error(message)
    sys.exit(message)


def _save_params_file(image, params):
    params_json = {
        '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#',
        'contentVersion': '1.0.0.0',
        'parameters': {}
    }

    params_json['parameters']['image'] = {
        'value': image['name']
    }

    params_json['parameters']['version'] = {
        'value': image['version']
    }

    for p in params:
        params_json['parameters'][p] = {
            'value': params[p]
        }

    with open(Path(image['path']) / BUILDER_PARAMS_FILE, 'w') as f:
        json.dump(params_json, f, ensure_ascii=False, indent=4, sort_keys=True)


def main(names, params, suffix, skip_build=False):

    gallery = gal.get()
    common = img.get_common()
    images = [img.get(n, gallery, common, suffix, ensure_azure=True) for n in names] if names else img.all(gallery, common, suffix, ensure_azure=True)

    for image in images:

        if image['build']:

            _save_params_file(image, params)

            if not skip_build:

                bicep_file = os.path.join(Path(__file__).resolve().parent, 'builder.bicep')
                params_file = '@' + os.path.join(image['path'], BUILDER_PARAMS_FILE)

                if 'tempResourceGroup' in image and image['tempResourceGroup']:
                    group_name = image['tempResourceGroup']
                    group = az.cli(['group', 'create', '-n', image['tempResourceGroup'], '-l', image['location']])
                else:
                    group_name = image['buildResourceGroup']

                group = az.cli(['deployment', 'group', 'create', '-n', image['name'], '-g', group_name, '-f', bicep_file, '-p', params_file, '--no-prompt'])

    if skip_build:
        log.warning('Skipping build execution because --skip-build was provided')


async def _process_image_async(name, params, gallery, common, suffix, skip_build):

    image = await img.get_async(name, gallery, common, suffix, ensure_azure=True)

    if image['build']:

        _save_params_file(image, params)

        if not skip_build:

            bicep_file = os.path.join(Path(__file__).resolve().parent, 'builder.bicep')
            params_file = '@' + os.path.join(image['path'], BUILDER_PARAMS_FILE)

            if 'tempResourceGroup' in image and image['tempResourceGroup']:
                group_name = image['tempResourceGroup']
                group = await az.cli_async(['group', 'create', '-n', image['tempResourceGroup'], '-l', image['location']])
            else:
                group_name = image['buildResourceGroup']

            group = await az.cli_async(['deployment', 'group', 'create', '-n', image['name'], '-g', group_name, '-f', bicep_file, '-p', params_file, '--no-prompt'])

    if skip_build:
        log.warning('Skipping build execution because --skip-build was provided')


async def main_async(names, params, suffix, skip_build=False):
    names = names if names else img.image_names()

    gallery = gal.get()
    common = img.get_common()
    build_imgs = await asyncio.gather(*[_process_image_async(n, params, gallery, common, suffix, skip_build) for n in names])


if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='Build custom images for Microsoft Dev Box using Packer then pubish them to an Azure Compute Gallery.'
                                     'This script asumes the presence of a gallery.yaml file in the root of the repository and image.yaml files in each subdirectory of the /images directory',
                                     epilog='example: python3 aci.py --suffix 22 --build')
    parser.add_argument('--images', '-i', nargs='*', help='names of images to build. if not specified all images will be')
    parser.add_argument('--async', '-a', dest='is_async', action='store_true', help='build images asynchronously. because the processes run in parallel, the output is not ordered')
    parser.add_argument('--changes', '-c', nargs='*', help='paths of the files that changed to determine which images to build. if not specified all images will be built')
    parser.add_argument('--suffix', '-s', help='suffix to append to the resource group name. if not specified, the current time will be used')
    parser.add_argument('--skip-build', action='store_true',
                        help='skip building images with packer or azure image builder depening on the builder property in the image definition yaml')

    parser.add_argument('--subnet-id', '-sni', help='The resource id of a subnet to use for the container instance. If this is not specified, the container instance will not be created in a virtual network and have a public ip address.')
    parser.add_argument('--storage-account', '-sa', help='The name of an existing storage account to use with the container instance. If not specified, the container instance will not mount a persistant file share.')
    parser.add_argument('--client-id', '-cid', required=True, help='The client (app) id for the service principal to use for authentication.')
    parser.add_argument('--client-secret', '-cs', required=True, help='The secret for the service principal to use for authentication.')
    parser.add_argument('--repository', '-r', required=True, help='The git repository that contains your image.yml and buiild scripts.')
    parser.add_argument('--revision', '-b', help='The git repository revision that contains your image.yml and buiild scripts.')
    parser.add_argument('--token', '-t', help='The PAT token to use when cloning the git repository.')

    args = parser.parse_args()

    subnet_id = args.subnet_id
    client_id = args.client_id
    client_secret = args.client_secret

    repo = repos.parse_url(args.repository)

    params = {
        'clientId': client_id,
        'clientSecret': client_secret,
        'repository': repo['url'].replace('https://', f'https://{args.token}@') if args.token else repo['url']
    }

    if args.revision:
        params['revision'] = args.revision

    if args.subnet_id:
        params['subnetId'] = args.subnet_id

    if args.storage_account:
        params['storageAccount'] = args.storage_account

    is_async = args.is_async
    skip_build = args.skip_build
    names = args.images if args.images else None

    suffix = args.suffix if args.suffix else datetime.now(timezone.utc).strftime('%Y%m%d%H%M')

    if is_async:
        asyncio.run(main_async(names, params, suffix, skip_build))
    else:
        main(names, params, suffix, skip_build)
