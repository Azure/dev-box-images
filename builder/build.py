# ------------------------------------
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
# ------------------------------------

import argparse
import asyncio
import json
import os
import sys
from datetime import datetime, timezone

import azure as az
import image as img
import loggers
import packer

is_github = os.environ.get('GITHUB_ACTIONS', False)

log = loggers.getLogger(__name__)


def error_exit(message):
    log.error(message)
    sys.exit(message)


def main(names, suffix, skip_build=False):

    gallery = img.get_gallery()
    common = img.get_common()
    images = [img.get(n, gallery, common, suffix, ensure_azure=True) for n in names] if names else img.all(gallery, common, suffix, ensure_azure=True)

    for image in images:

        if image['build']:

            if 'subscription' in image and image['subscription']:
                az.cli(f'az account set -s {image["subscription"]}')

            if image['builder'] == 'packer':
                packer.save_vars_file(image)

                if not skip_build:
                    packer.execute(image)

            elif image['builder'] == 'azure':
                az.save_params_file(image)

                if not skip_build:
                    az.create_run_template(image)
            else:
                error_exit(f'image.yaml for {image["name"]} has an invalid builder property value {image["builder"]}')

    if skip_build:
        log.warning('Skipping build execution because --skip-build was provided')


async def _process_image_async(name, gallery, common, suffix, skip_build):

    image = await img.get_async(name, gallery, common, suffix, ensure_azure=True)

    if image['build']:
        if image['builder'] == 'packer':
            await packer.save_vars_file_async(image)

            if not skip_build:
                await packer.execute_async(image)

        elif image['builder'] == 'azure':
            az.save_params_file(image)

            if not skip_build:
                await az.create_run_template_async(image)
        else:
            error_exit(f'image.yaml for {image["name"]} has an invalid builder property value {image["builder"]}')

    if skip_build:
        log.warning('Skipping build execution because --skip-build was provided')

    return image


async def main_async(names, suffix, skip_build=False):
    names = names if names else img.image_names()

    gallery = img.get_gallery()
    common = img.get_common()
    build_imgs = await asyncio.gather(*[_process_image_async(n, gallery, common, suffix, skip_build) for n in names])
    # set GitHub output
    if is_github:
        print("::set-output name=matrix::{}".format(json.dumps({'include': build_imgs})))
        print("::set-output name=build::{}".format(len(build_imgs) > 0))

if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='Build custom images for Microsoft Dev Box using Packer then pubish them to an Azure Compute Gallery.'
                                     'This script asumes the presence of a gallery.yaml file in the root of the repository and image.yaml files in each subdirectory of the /images directory',
                                     epilog='example: python3 build.py --suffix 22 --packer')
    parser.add_argument('--async', '-a', dest='is_async', action='store_true', help='build images asynchronously. because the processes run in parallel, the output is not ordered')
    parser.add_argument('--images', '-i', nargs='*', help='names of images to build. if not specified all images will be')
    parser.add_argument('--changes', '-c', nargs='*', help='paths of the files that changed to determine which images to build. if not specified all images will be built')
    parser.add_argument('--suffix', '-s', help='suffix to append to the resource group name. if not specified, the current time will be used')
    parser.add_argument('--skip-build', dest='skip_build', action='store_true',
                        help='skip building images with packer or azure image builder depening on the builder property in the image definition yaml')

    args = parser.parse_args()

    is_async = args.is_async
    skip_build = args.skip_build
    names = args.images if args.images else None

    suffix = args.suffix if args.suffix else datetime.now(timezone.utc).strftime('%Y%m%d%H%M')

    if is_async:
        asyncio.run(main_async(names, suffix, skip_build))
    else:
        main(names, suffix, skip_build)
