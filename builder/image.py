# ------------------------------------
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
# ------------------------------------

import argparse
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

import azure as az
import loggers
import syaml

IMAGE_REQUIRED_PROPERTIES = ['publisher', 'offer', 'sku', 'version', 'os', 'replicaLocations']
IMAGE_ALLOWED_PROPERTIES = ['publisher', 'offer', 'sku', 'version', 'os', 'replicaLocations', 'description',
                            'buildResourceGroup', 'keyVault', 'virtualNetwork', 'virtualNetworkSubnet',
                            'virtualNetworkResourceGroup', 'subscription']

COMMON_ALLOWED_PROPERTIES = ['publisher', 'offer', 'replicaLocations', 'buildResourceGroup', 'keyVault',
                             'virtualNetwork', 'virtualNetworkSubnet', 'virtualNetworkResourceGroup', 'subscription']

GALLERY_REQUIRED_PROPERTIES = ['name', 'resourceGroup']
GALLERY_ALLOWED_PROPERTIES = ['name', 'resourceGroup', 'subscription']

log = loggers.getLogger(__name__)

# indicates if the script is running in the docker container
in_builder = os.environ.get('ACI_IMAGE_BUILDER', False)

repo = Path('/mnt/repo') if in_builder else Path(__file__).resolve().parent.parent
images_root = repo / 'images'

default_suffix = datetime.now(timezone.utc).strftime('%Y%m%d%H%M')


def error_exit(message):
    log.error(message)
    sys.exit(message)


def get_gallery() -> dict:
    '''Get the gallery properties from the gallery.yaml file in the root of the repo'''
    gallery_path = syaml.get_file(repo, 'gallery', required=True)
    gallery = syaml.parse(gallery_path, required=GALLERY_REQUIRED_PROPERTIES, allowed=GALLERY_ALLOWED_PROPERTIES)

    log.info(f'Found gallery properties in {gallery_path}')
    log.info(f'Gallery properties:')
    for line in json.dumps(gallery, indent=4).splitlines():
        log.info(line)

    return gallery


def get_common() -> dict:
    '''Get the common properties from the images.yaml file in the root of the images directory'''
    images_path = syaml.get_file(images_root, 'images', required=False)

    if images_path is None:
        return {}

    common = syaml.parse(images_path, allowed=COMMON_ALLOWED_PROPERTIES)

    log.info(f'Found common image properties in {images_path}')
    log.info(f'Common image properties:')
    for line in json.dumps(common, indent=4).splitlines():
        log.info(line)

    return common


def _has_key_and_value(obj, key):
    return key in obj and obj[key]


def _missing_key_or_value(obj, key):
    return key not in obj or not obj[key]


def _pre_validate(image):
    '''Validate the image properties without doing any azure stuff'''
    log.info(f'Validating image {image["name"]} (initional)')

    if _missing_key_or_value(image, 'name'):
        error_exit(f'name was not correctly applied to image object for image {image}')

    if _missing_key_or_value(image, 'path'):
        error_exit(f'path was not correctly applied to image object for image {image}')

    log.info(f'Image {image["name"]} passed initional validation')


def _validate(image):
    '''Validate the image properties after supplementing azure stuff'''
    log.info(f'Validating image {image["name"]} (full)')

    if _has_key_and_value(image, 'buildResourceGroup') and _has_key_and_value(image, 'tempResourceGroup'):
        error_exit(f'image.yaml for {image["name"]} has values for both buildResourceGroup and tempResourceGroup properties. must only define one')

    if _has_key_and_value(image, 'tempResourceGroup'):
        if _missing_key_or_value(image, 'location'):
            error_exit(f'image.yaml for {image["name"]} has a tempResourceGroup property but no location property')

    elif _has_key_and_value(image, 'buildResourceGroup'):
        if _has_key_and_value(image, 'location'):
            error_exit(f'image.yaml for {image["name"]} has a buildResourceGroup property and a location property. must not define both')

    else:
        error_exit(f'image.yaml for {image["name"]} has no value for buildResourceGroup property and no value for tempResourceGroup property. must define one')

    if _missing_key_or_value(image, 'subscription'):
        error_exit(f'image property subscription was not correctly applied to image object for {image["name"]}')

    if _missing_key_or_value(image, 'gallery'):
        error_exit(f'gallery was not correctly applied to image object for {image["name"]}')

    for key in ['name', 'resourceGroup', 'subscription']:
        if _missing_key_or_value(image['gallery'], key):
            error_exit(f'gallery property {key} was not correctly applied to image object for {image["name"]}')

    log.info(f'Image {image["name"]} passed full validation')


def _get(image_name, gallery, common=None) -> dict:
    '''Get the image properties from the image.yaml file'''
    image_dir = images_root / image_name
    log.info(f'Getting image {image_name} from {image_dir}')

    image_path = syaml.get_file(image_dir, 'image', required=True)
    image = syaml.parse(image_path)

    if common:  # merge common properties into image properties
        temp = common.copy()
        temp.update(image)
        image = temp.copy()

    # validate all the user-defined properties
    syaml.validate(image_path, image, required=IMAGE_REQUIRED_PROPERTIES, allowed=IMAGE_ALLOWED_PROPERTIES)

    image['name'] = Path(image_dir).name
    image['path'] = f'{image_dir}'

    image['gallery'] = gallery

    # if subscription is defined in gallery but not image, use gallery subscription for image
    if _missing_key_or_value(image, 'subscription') and _has_key_and_value(gallery, 'subscription'):
        image['subscription'] = gallery['subscription']
    # if subscription is defined in image but not gallery, use image subscription for gallery
    if _missing_key_or_value(image['gallery'], 'subscription') and _has_key_and_value(image, 'subscription'):
        image['gallery']['subscription'] = image['subscription']

    log.info(f'Found (initial) image properties in {image_path}')
    for line in json.dumps(image, indent=4).splitlines():
        log.info(line)

    _pre_validate(image)

    return image


def get(image_name, gallery, common=None, suffix=None, ensure_azure=False) -> dict:
    '''Get the image properties from the image.yaml file optionally supplementing with info from azure'''
    image = _get(image_name, gallery, common)

    if ensure_azure:

        # _get() will set the subscription on the image and the gallery if one was
        # defined on either, if none was defined, set the subscription on the image
        if _missing_key_or_value(image, 'subscription'):
            sub = az.get_sub()
            image['subscription'] = sub
        # and the gallery
        if _missing_key_or_value(image['gallery'], 'subscription'):
            image['gallery']['subscription'] = image['subscription']

        build, image_def = az.ensure_image_def_version(image)
        image['build'] = build

        # if buildResourceGroup is not provided we'll provide a name and location for the resource group
        if _missing_key_or_value(image, 'buildResourceGroup'):
            suffix = suffix if suffix else default_suffix
            image['location'] = image_def['location']
            image['tempResourceGroup'] = f'{image["gallery"]["name"]}-{image["name"]}-{suffix}'

        log.info(f'Image {image["name"]} properties:')
        for line in json.dumps(image, indent=4).splitlines():
            log.info(line)

        _validate(image)

    return image


def all(gallery, common=None, suffix=None, ensure_azure=False) -> list:
    '''Get all the image properties from the image.yaml files'''
    common = common if common else get_common()
    names = image_names()
    for name in names:
        log.warning(f'Getting image {name}')
    images = [get(i, gallery, common, suffix, ensure_azure) for i in image_names()]
    return images


def image_names() -> list:
    '''Get the list of image names from the images directory'''
    names = []

    # walk the images directory and find all the image.yml/image.yaml files
    for dirpath, dirnames, files in os.walk(images_root):
        # os.walk includes the root directory (i.e. repo/images) so we need to skip it
        if not images_root.samefile(dirpath) and Path(dirpath).parent.samefile(images_root):
            names.append(Path(dirpath).name)

    return names

# ----------------
# async functions
# ----------------


async def get_async(image_name, gallery, common=None, suffix=None, ensure_azure=False) -> dict:
    '''Get the image properties from the image.yaml file optionally supplementing with info from azure'''
    image = _get(image_name, gallery, common)

    if ensure_azure:

        # _get() will set the subscription on the image and the gallery if one was
        # defined on either, if none was defined, set the subscription on the image
        if _missing_key_or_value(image, 'subscription'):
            sub = await az.get_sub_async()
            image['subscription'] = sub
        # and the gallery
        if _missing_key_or_value(image['gallery'], 'subscription'):
            image['gallery']['subscription'] = image['subscription']

        build, image_def = await az.ensure_image_def_version_async(image)
        image['build'] = build

        # if buildResourceGroup is not provided we'll provide a name and location for the resource group
        if 'buildResourceGroup' not in image or not image['buildResourceGroup']:
            suffix = suffix if suffix else default_suffix
            image['location'] = image_def['location']
            image['tempResourceGroup'] = f'{image["gallery"]["name"]}-{image["name"]}-{suffix}'

        log.info(f'Image {image["name"]} properties:')
        for line in json.dumps(image, indent=4).splitlines():
            log.info(line)

        _validate(image)

    return image


if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='Get image properties from image.yaml files')
    parser.add_argument('--images', '-i', nargs='*', help='names of images to include. if not specified all images will be')

    args = parser.parse_args()

    gallery = get_gallery()
    common = get_common()

    # images = [get(i, gallery, common) for i in args.images] if args.images else all(gallery, common)
    images = [get(i, gallery, common, 'suffix', ensure_azure=True) for i in args.images] if args.images else all(gallery, common, 'suffix', ensure_azure=True)

    for image in images:
        print(json.dumps(image, indent=4))
