# ------------------------------------
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
# ------------------------------------

import argparse
import asyncio
import sys
from datetime import datetime, timezone

import azure as az
import image as img
import loggers
import repos

BUILDER_PARAMS_FILE = 'builder.parameters.json'

log = loggers.getLogger(__name__)


def error_exit(message):
    log.error(message)
    sys.exit(message)


def main(gallery, common, names, params, suffix, skip_build=False):
    if names is None:
        images = img.all(gallery, common, suffix, ensure_azure=True)
    else:
        images = [img.get(n, gallery, common, suffix, ensure_azure=True) for n in names]

    for image in images:

        if image['build']:
            params_file = az.save_params_file(image, params, BUILDER_PARAMS_FILE)

            if not skip_build:
                az.deploy_builder(image, params_file)

    if skip_build:
        log.warning('Skipping build execution because --skip-build was provided')


# ----------------
# async functions
# ----------------


async def main_async(gallery, common, names, params, suffix, skip_build=False):
    if names is None:
        names = img.image_names()

    async def _process_image_async(name):
        image = await img.get_async(name, gallery, common, suffix, ensure_azure=True)

        if image['build']:
            params_file = az.save_params_file(image, params, BUILDER_PARAMS_FILE)

            if not skip_build:
                await az.deploy_builder_async(image, params_file)

        if skip_build:
            log.warning('Skipping build execution because --skip-build was provided')

    await asyncio.gather(*[_process_image_async(n) for n in names])


if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='Build custom images for Microsoft Dev Box using Packer then pubish them to an Azure Compute Gallery.'
                                     'This script asumes the presence of a gallery.yaml file in the root of the repository and image.yaml files in each subdirectory of the /images directory',
                                     epilog='example: python3 aci.py --suffix 22 --build')
    parser.add_argument('--images', '-i', nargs='*', help='names of images to build. if not specified all images will be')
    parser.add_argument('--async', '-a', dest='is_async', action='store_true', help='build images asynchronously. because the processes run in parallel, the output is not ordered')
    parser.add_argument('--changes', '-c', nargs='*', help='paths of the files that changed to determine which images to build. if not specified all images will be built')
    parser.add_argument('--suffix', '-s', help='suffix to append to the resource group name. if not specified, the current time will be used')
    parser.add_argument('--skip-build', action='store_true', help='skip building images with packer')

    parser.add_argument('--subnet-id', '-sni', help='The resource id of a subnet to use for the container instance. If this is not specified, the container instance will not be created in a virtual network and have a public ip address.')
    parser.add_argument('--storage-account', '-sa', help='The name of an existing storage account to use with the container instance. If not specified, the container instance will not mount a persistant file share.')
    parser.add_argument('--client-id', '-cid', required=True, help='The client (app) id for the service principal to use for authentication.')
    parser.add_argument('--client-secret', '-cs', required=True, help='The secret for the service principal to use for authentication.')
    parser.add_argument('--repository', '-r', required=True, help='The git repository that contains your image.yml and buiild scripts.')
    parser.add_argument('--revision', '-b', help='The git repository revision that contains your image.yml and buiild scripts.')
    parser.add_argument('--token', '-t', help='The PAT token to use when cloning the git repository.')

    args = parser.parse_args()

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

    gallery = img.get_gallery()
    common = img.get_common()

    if is_async:
        asyncio.run(main_async(gallery, common, names, params, suffix, skip_build))
    else:
        main(gallery, common, names, params, suffix, skip_build)
