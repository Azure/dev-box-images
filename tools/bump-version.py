# ------------------------------------
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
# ------------------------------------

import argparse
import os
from pathlib import Path

from packaging.version import parse  # pylint: disable=unresolved-import

parser = argparse.ArgumentParser()
parser.add_argument('--major', action='store_true', help='bump major version')
parser.add_argument('--minor', action='store_true', help='bump minor version')
parser.add_argument('--images', nargs='*', help='images to bump images version, all images if not specified')

args = parser.parse_args()

major = args.major
minor = args.minor

if major and minor:
    raise ValueError('usage error: --major | --minor')

images = args.images
allimages = not images

toolspath = Path(__file__).resolve().parent
imgspath = Path(toolspath.parent / 'images')

paths = []

for imgdir, dirs, files in os.walk(imgspath):
    if imgspath.samefile(imgdir):
        if not allimages:
            baddirs = [i for i in images if i not in dirs]
            if baddirs:
                raise ValueError('directories not found under /images: [ {} ]'.format(', '.join(baddirs)))
    else:
        imgname = Path(imgdir).name
        if allimages or imgname in images:
            # print('bumping version in {}'.format(imgname))
            paths.extend([Path(imgdir) / f for f in files if f.lower() == 'image.yml' or f.lower() == 'image.yaml'])

for path in paths:

    version = None

    image = Path(path).parent.name

    with open(path, 'r') as f:
        for line in f:
            if line.startswith('version: '):
                version = line.split('version: ')[1].strip()
                break

    if not version:
        raise ValueError(f'no version found for {image}')

    v = parse(version)

    n_major = v.major + 1 if major else v.major
    n_minor = 0 if major else v.minor + 1 if minor else v.minor
    n_patch = 0 if major or minor else v.micro + 1

    n = parse('{}.{}.{}'.format(n_major, n_minor, n_patch))

    print(f'bumping version for {image} {v.public} -> {n.public}')

    with open(path, 'r') as f:
        yml = f.read()

    yml = yml.replace(f'version: {v.public}', f'version: {n.public}')

    with open(path, 'w') as f:
        f.write(yml)
