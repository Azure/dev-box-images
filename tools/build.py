import argparse
import asyncio
import json
from datetime import datetime, timezone
from pathlib import Path

import azure
import gallery
import images
import packer

this_path = Path(__file__).resolve().parent
repo_root = this_path.parent
images_root = repo_root / 'images'

parser = argparse.ArgumentParser(description='Build custom images for Microsoft Dev Box using Packer then pubish them to an Azure Compute Gallery.'
                                 'This script asumes the presence of a gallery.yaml file in the root of the repository and image.yaml files in each subdirectory of the /images directory',
                                 epilog='example: python3 build.py --suffix 22 --packer')
parser.add_argument('--async', '-a', dest='is_async', action='store_true', help='build images asynchronously. because the processes run in parallel, the output is not ordered')
parser.add_argument('--images', '-i', nargs='*', help='names of images to build. if not specified all images will be')
parser.add_argument('--changes', '-c', nargs='*', help='paths of the files that changed to determine which images to build. if not specified all images will be built')
parser.add_argument('--suffix', '-s', help='suffix to append to the resource group name. if not specified, the current time will be used')
parser.add_argument('--packer', '-p', dest='run_packer', action='store_true',
                    help='execute packer init and build on the images. if not specified, the images will not be built, but the variable files will still be created')

args = parser.parse_args()

is_async = args.is_async
run_packer = args.run_packer

suffix = args.suffix if args.suffix else datetime.now(timezone.utc).strftime('%Y%m%d%H%M')

gal = gallery.get()
imgs = [images.get(i) for i in args.images] if args.images else images.all()

for img in imgs:
    img['gallery'] = gal


def main():
    for img in imgs:

        build, imgdef = azure.ensure_image_def_version(img)
        img['build'] = build

        # if buildResourceGroup is not provided we'll provide a name and location for the resource group
        if 'buildResourceGroup' not in img or not img['buildResourceGroup']:
            img['location'] = imgdef['location']
            img['tempResourceGroup'] = f'{img["gallery"]["name"]}-{img["name"]}-{suffix}'

    build_imgs = [i for i in imgs if i['build']]

    # set GitHub output
    print("::set-output name=images::{}".format(json.dumps({'include': build_imgs})))
    print("::set-output name=build::{}".format(len(build_imgs) > 0))

    packer.save_vars_files(build_imgs)

    if run_packer:
        for img in build_imgs:
            print(f'::group::Build {img["name"]}')
            packer.execute(img)
            print(f'::endgroup::')
    else:
        print('::warning:: skipping packer execution because --packer | -p was not specified')
        print('skipping packer execution because --packer | -p was not specified')


async def process_image_async(img):
    build, imgdef = await azure.ensure_image_def_version_async(img)
    img['build'] = build

    # if buildResourceGroup is not provided we'll provide a name and location for the resource group
    if 'buildResourceGroup' not in img or not img['buildResourceGroup']:
        img['location'] = imgdef['location']
        img['tempResourceGroup'] = f'{img["gallery"]["name"]}-{img["name"]}-{suffix}'

    if img['build']:
        await packer.save_vars_file_async(img)
        if run_packer:
            await packer.execute_async(img)
        else:
            print('::warning:: skipping packer execution because --packer | -p was not specified')
            print('skipping packer execution because --packer | -p was not specified')

    return img


async def main_async():
    build_imgs = await asyncio.gather(*[process_image_async(i) for i in imgs])
    # set GitHub output
    print("::set-output name=matrix::{}".format(json.dumps({'include': build_imgs})))
    print("::set-output name=build::{}".format(len(build_imgs) > 0))


if is_async:
    asyncio.run(main_async())
else:
    main()
