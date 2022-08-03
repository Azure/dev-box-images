import argparse
import asyncio
import json
import os
import shutil
import subprocess
from pathlib import Path

import azure

this_path = Path(__file__).resolve().parent
repo_root = this_path.parent
images_root = repo_root / 'images'


default_pkr_vars = [
    'subscription',
    'name',
    'location',
    'version',
    'tempResourceGroup',
    'buildResourceGroup',
    'gallery',
    'replicaLocations',
    'repos',
    'branch',
    'commit'
]


def get_vars(image):
    try:
        packer = shutil.which('packer')
        proc = subprocess.run([packer, 'inspect', '-machine-readable', image['path']], capture_output=True, check=True, text=True)
        if proc.stdout:
            return [v.strip().split('var.')[1].split(':')[0] for v in proc.stdout.split('\\n') if v.startswith('var.')]
        return default_pkr_vars
    except subprocess.CalledProcessError:
        return default_pkr_vars


async def get_vars_async(image):
    try:
        packer = shutil.which('packer')
        proc = await asyncio.create_subprocess_exec(packer, 'inspect', '-machine-readable', image['path'], stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE)
        stdout, stderr = await proc.communicate()
        if stdout:
            return [v.strip().split('var.')[1].split(':')[0] for v in stdout.decode().split('\\n') if v.startswith('var.')]
        return default_pkr_vars
    except subprocess.CalledProcessError:
        return default_pkr_vars


def save_vars_file(image, sub=None):
    sub = sub if sub else azure.get_sub()

    pkr_vars = get_vars(image)

    auto_vars = {
        'subscription': sub,
    }

    for v in pkr_vars:
        if v in image and image[v]:
            auto_vars[v] = image[v]

    with open(Path(image['path']) / 'vars.auto.pkrvars.json', 'w') as f:
        json.dump(auto_vars, f, ensure_ascii=False, indent=4, sort_keys=True)


async def save_vars_file_async(image, sub=None):
    sub = sub if sub else await azure.get_sub_async()

    pkr_vars = await get_vars_async(image)

    auto_vars = {
        'subscription': sub,
    }

    for v in pkr_vars:
        if v in image and image[v]:
            auto_vars[v] = image[v]

    with open(Path(image['path']) / 'vars.auto.pkrvars.json', 'w') as f:
        json.dump(auto_vars, f, ensure_ascii=False, indent=4, sort_keys=True)


def save_vars_files(images):
    sub = azure.get_sub()

    for image in images:
        save_vars_file(image, sub)


def init(image):
    packer = shutil.which('packer')
    print(f'executing packer init for {image["name"]}')
    proc = subprocess.run([packer, 'init', image['path']], check=True, text=True)
    print(f'done executing packer init for {image["name"]}')
    return proc.returncode


async def init_async(image):
    packer = shutil.which('packer')
    print(f'executing packer init for {image["name"]}')
    proc = await asyncio.create_subprocess_exec(packer, 'init', image['path'])
    stdout, stderr = await proc.communicate()
    print(f'done executing packer init for {image["name"]}')
    print(f'[packer init for {image["name"]} exited with {proc.returncode}]')
    return proc.returncode


def build(image):
    packer = shutil.which('packer')
    print(f'executing packer build for {image["name"]}')
    proc = subprocess.run([packer, 'build', '-force', image['path']], check=True, text=True)
    print(f'done executing packer build for {image["name"]}')
    return proc.returncode


async def build_async(image):
    packer = shutil.which('packer')
    print(f'executing packer build for {image["name"]}')
    proc = await asyncio.create_subprocess_exec(packer, 'build', '-force', image['path'])
    stdout, stderr = await proc.communicate()
    print(f'done executing packer build for {image["name"]}')
    print(f'[packer build for {image["name"]} exited with {proc.returncode}]')
    return proc.returncode


def execute(image):
    i = init(image)
    return build(image) if i == 0 else i


async def execute_async(image):
    i = await init_async(image)
    return await build_async(image) if i == 0 else i


def main(img_name):
    img_dir = images_root / img_name

    if not os.path.isdir(img_dir):
        print(f'::error:: directory for image {img_name} not found at {img_dir}')
        raise ValueError(f'directory for image {img_name} not found at {img_dir}')

    if not os.path.isfile(img_dir / 'vars.auto.pkrvars.json'):
        print(f'::error:: vars.auto.pkrvars.json not found in {img_dir} must execute build.py first')
        raise ValueError(f'vars.auto.pkrvars.json not found in {img_dir} must execute build.py first')

    image = {}
    image['name'] = Path(img_dir).name
    image['path'] = f'{img_dir}'

    execute(image)


if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='builds a single image. assumes the image is already using the build.py without the --packer | -p arg.')
    parser.add_argument('--image', '-i', required=True, help='name of the image to build')

    args = parser.parse_args()

    img_name = args.image
    main(img_name)
