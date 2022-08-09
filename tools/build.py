import argparse
import asyncio
import json
import os
from datetime import datetime, timezone
from pathlib import Path

import azure
import gallery
import images
import packer

this_path = Path(__file__).resolve().parent
repo_root = this_path.parent
images_root = repo_root / 'images'

is_github = os.environ.get('GITHUB_ACTIONS', False)


parser = argparse.ArgumentParser(description='Build custom images for Microsoft Dev Box using Packer then pubish them to an Azure Compute Gallery.'
                                 'This script asumes the presence of a gallery.yaml file in the root of the repository and image.yaml files in each subdirectory of the /images directory',
                                 epilog='example: python3 build.py --suffix 22 --packer')
parser.add_argument('--async', '-a', dest='is_async', action='store_true', help='build images asynchronously. because the processes run in parallel, the output is not ordered')
parser.add_argument('--images', '-i', nargs='*', help='names of images to build. if not specified all images will be')
parser.add_argument('--changes', '-c', nargs='*', help='paths of the files that changed to determine which images to build. if not specified all images will be built')
parser.add_argument('--suffix', '-s', help='suffix to append to the resource group name. if not specified, the current time will be used')
parser.add_argument('--build', '-b', dest='run_build', action='store_true', help='build images with packer or azure image builder depening on the builder property in the image definition yaml')


args = parser.parse_args()

is_async = args.is_async
run_build = args.run_build

suffix = args.suffix if args.suffix else datetime.now(timezone.utc).strftime('%Y%m%d%H%M')

gal = gallery.get()
imgs = [images.get(i) for i in args.images] if args.images else images.all()

for img in imgs:
    img['gallery'] = gal


def log_message(msg):
    print(f'[tools/build] {msg}')


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


def main():
    for img in imgs:

        build, imgdef = azure.ensure_image_def_version(img)
        img['build'] = build

        # if buildResourceGroup is not provided we'll provide a name and location for the resource group
        if 'buildResourceGroup' not in img or not img['buildResourceGroup']:
            img['location'] = imgdef['location']
            img['tempResourceGroup'] = f'{img["gallery"]["name"]}-{img["name"]}-{suffix}'

        if not img['build']:
            log_warning('skipping build execution for because --build | -b was not provided')

    build_imgs = [i for i in imgs if i['build']]

    # set GitHub output
    if is_github:
        print("::set-output name=images::{}".format(json.dumps({'include': build_imgs})))
        print("::set-output name=build::{}".format(len(build_imgs) > 0))

    for img in build_imgs:
        is_github and print(f'::group::Build {img["name"]}')

        if img['builder'] == 'packer':
            packer.save_vars_files(img)

            if run_build:
                packer.execute(img)

        elif img['builder'] == 'azure':
            azure.save_params_files(build_imgs)

            if run_build:
                bicep_file = os.path.join(img['path'], 'image.bicep')
                params_file = '@' + os.path.join(img['path'], 'image.parameters.json')

                existing = azure.cli(['image', 'builder', 'show', '-g', img['gallery']['resourceGroup'], '-n', img['name']])
                if existing:
                    log_warning(f'image template {img["name"]} already exists in {img["gallery"]["resourceGroup"]}. deleting')
                    azure.cli(['image', 'builder', 'delete', '-g', img['gallery']['resourceGroup'], '-n', img['name']])

                log_message(f'Creating image template for {img["name"]}')
                log_message(f'Deploying bicep template for image template: {bicep_file}')
                group = azure.cli(['deployment', 'group', 'create', '-n', img['name'], '-g', img['gallery']['resourceGroup'], '-f', bicep_file, '-p', params_file, '--no-prompt'])

                log_message(f'Executing build on image template: {img["name"]}')
                build = azure.cli(['image', 'builder', 'run', '-g', img['gallery']['resourceGroup'], '-n', img['name']])

        else:
            log_error(f'image.yaml for {img["name"]} has an invalid builder property value {img["builder"]}')

        is_github and print(f'::endgroup::')

    if not run_build:
        log_warning('skipping build execution because --build | -b was not provided')


async def process_image_async(img):
    build, imgdef = await azure.ensure_image_def_version_async(img)
    img['build'] = build

    # if buildResourceGroup is not provided we'll provide a name and location for the resource group
    if 'buildResourceGroup' not in img or not img['buildResourceGroup']:
        img['location'] = imgdef['location']
        img['tempResourceGroup'] = f'{img["gallery"]["name"]}-{img["name"]}-{suffix}'

    if img['build']:
        if img['builder'] == 'packer':
            await packer.save_vars_file_async(img)
            if run_build:
                await packer.execute_async(img)
        elif img['builder'] == 'azure':
            # TODO: async azure parameters file creation
            azure.save_params_file(img)
            # TODO: async azure cli
            if run_build:
                bicep_file = os.path.join(img['path'], 'image.bicep')
                params_file = '@' + os.path.join(img['path'], 'image.parameters.json')

                log_message(f'Creating image template for {img["name"]}')
                log_message(f'Deploying bicep template for image template: {bicep_file}')
                group = azure.cli(['deployment', 'group', 'create', '-g', img['gallery']['resourceGroup'], '-f', bicep_file, '-p', params_file, '--no-prompt'])

                log_message(f'Executing build on image template: {img["name"]}')
                build = azure.cli(['image', 'builder', 'run', '-g', img['gallery']['resourceGroup'], '-n', img['name']])
        else:
            log_error(f'image.yaml for {img["name"]} has an invalid builder property value {img["builder"]}')

    if not run_build:
        log_warning('skipping build execution because --build | -b was not provided')

    return img


async def main_async():
    build_imgs = await asyncio.gather(*[process_image_async(i) for i in imgs])
    # set GitHub output
    if is_github:
        print("::set-output name=matrix::{}".format(json.dumps({'include': build_imgs})))
        print("::set-output name=build::{}".format(len(build_imgs) > 0))


if is_async:
    asyncio.run(main_async())
else:
    main()
