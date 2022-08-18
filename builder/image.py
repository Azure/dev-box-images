import argparse
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

import azure
import loggers
import syaml

REQUIRED_PROPERTIES = ['publisher', 'offer', 'sku', 'version', 'os', 'replicaLocations', 'builder']

log = loggers.getLogger(__name__)

in_builder = os.environ.get('ACI_IMAGE_BUILDER', False)

repo = Path('/mnt/repo') if in_builder else Path(__file__).resolve().parent.parent
images_root = repo / 'images'

default_suffix = datetime.now(timezone.utc).strftime('%Y%m%d%H%M')


def error_exit(message):
    log.error(message)
    sys.exit(message)


def get_common() -> dict:
    permitted_properties = ['publisher', 'offer', 'replicaLocations', 'builder', 'buildResourceGroup',
                            'keyVault', 'virtualNetwork', 'virtualNetworkSubnet', 'virtualNetworkResourceGroup', 'subscription']

    images_yaml = os.path.isfile(os.path.join(images_root, 'images.yaml'))
    images_yml = os.path.isfile(os.path.join(images_root, 'images.yml'))

    if not images_yaml and not images_yml:
        return {}

    if images_yaml and images_yml:
        error_exit("found both 'images.yaml' and 'images.yml' in root of repository. only one images yaml file allowed")

    images_path = images_root / 'images.yaml' if images_yaml else images_root / 'images.yml'

    common = syaml.parse(images_path)

    for key in common:
        if key not in permitted_properties:
            error_exit(f'{key} is not a permitted property in {images_path}')

    log.info(f'Found common image properties in {images_path}')
    log.info(f'Common image properties:')
    for line in json.dumps(common, indent=4).splitlines():
        log.info(line)

    return common


def _validate(image):
    log.info(f'Validating image {image["name"]}')

    for required_property in REQUIRED_PROPERTIES:
        if required_property not in image:
            error_exit(f'image.yaml for {image["name"]} is missing required property {required_property}')
        if not image[required_property]:
            error_exit(f'image.yaml for {image["name"]} is missing a value for required property {required_property}')
    if image['builder'] not in ['packer', 'azure']:
        error_exit(f'image.yaml for {image["name"]} has an invalid builder property value {image["builder"]}')
    log.info(f'Image {image["name"]} passed validation')


def validate(image):
    log.info(f'Validating image {image["name"]}')

    if 'buildResourceGroup' in image and image['buildResourceGroup'] and 'tempResourceGroup' in image and image['tempResourceGroup']:
        error_exit(f'image.yaml for {image["name"]} has values for both buildResourceGroup and tempResourceGroup properties. must only define one')

    if 'tempResourceGroup' in image and image['tempResourceGroup']:
        if 'location' not in image or not image['location']:
            error_exit(f'image.yaml for {image["name"]} has a tempResourceGroup property but no location property')
    elif 'buildResourceGroup' in image and image['buildResourceGroup']:
        if 'location' in image and image['location']:
            error_exit(f'image.yaml for {image["name"]} has a buildResourceGroup property and a location property. must not define both')
    else:
        error_exit(f'image.yaml for {image["name"]} has no value for buildResourceGroup property and no value for tempResourceGroup property. must define one')

    log.info(f'Image {image["name"]} passed validation')


def _get(image_name, gallery, common=None) -> dict:
    image_dir = images_root / image_name
    log.info(f'Getting image {image_name} from {image_dir}')

    if not os.path.isdir(image_dir):
        error_exit(f'Directory for image {image_name} not found at {image_dir}')

    image_yaml = os.path.isfile(os.path.join(image_dir, 'image.yaml'))
    image_yml = os.path.isfile(os.path.join(image_dir, 'image.yml'))

    if not image_yaml and not image_yml:
        error_exit(f'image.yaml or image.yml not found {image_dir}')

    if image_yaml and image_yml:
        error_exit(f"Found both 'image.yaml' and 'image.yml' in {image_dir} of repository. only one image yaml file allowed")

    image_path = image_dir / 'image.yaml' if image_yaml else image_dir / 'image.yml'

    image = syaml.parse(image_path)
    image['name'] = Path(image_dir).name
    image['path'] = f'{image_dir}'

    if 'builder' in image and image['builder']:
        if image['builder'].lower() in ['az', 'azure', 'aib', 'azureimagebuilder' 'azure-image-builder', 'imagebuilder', 'image-builder']:
            image['builder'] = 'azure'
        elif image['builder'].lower() in ['packer', 'pkr']:
            image['builder'] = 'packer'
    else:
        image['builder'] = 'packer'

    if common:
        temp = common.copy()
        temp.update(image)
        image = temp.copy()

    image['gallery'] = gallery

    # if subscription is defined in gallery but not image, use gallery subscription for image
    if 'subscription' not in image or not image['subscription']:
        if 'subscription' in gallery and gallery['subscription']:
            image['subscription'] = gallery['subscription']
    # if subscription is defined in imag but not gallery, use image subscription for gallery
    elif 'subscription' in image and image['subscription']:
        if 'subscription' not in gallery or not gallery['subscription']:
            gallery['subscription'] = image['subscription']

    _validate(image)

    return image


def get(image_name, gallery, common=None, suffix=None, ensure_azure=False) -> dict:

    image = _get(image_name, gallery, common)

    if ensure_azure:

        if 'subscription' not in image or not image['subscription']:
            sub = azure.get_sub()
            image['subscription'] = sub
        if 'subscription' not in gallery or not gallery['subscription']:
            gallery['subscription'] = image['subscription']

        build, image_def = azure.ensure_image_def_version(image)
        image['build'] = build

        # if buildResourceGroup is not provided we'll provide a name and location for the resource group
        if 'buildResourceGroup' not in image or not image['buildResourceGroup']:
            suffix = suffix if suffix else default_suffix
            image['location'] = image_def['location']
            image['tempResourceGroup'] = f'{image["gallery"]["name"]}-{image["name"]}-{suffix}'

        log.info(f'Image {image["name"]} properties:')
        for line in json.dumps(image, indent=4).splitlines():
            log.info(line)

        validate(image)

    return image


async def get_async(image_name, gallery, common=None, suffix=None, ensure_azure=False) -> dict:

    image = _get(image_name, gallery, common)

    if ensure_azure:

        if 'subscription' not in image or not image['subscription']:
            sub = await azure.get_sub_async()
            image['subscription'] = sub
        if 'subscription' not in gallery or not gallery['subscription']:
            gallery['subscription'] = image['subscription']

        build, image_def = await azure.ensure_image_def_version_async(image)
        image['build'] = build

        # if buildResourceGroup is not provided we'll provide a name and location for the resource group
        if 'buildResourceGroup' not in image or not image['buildResourceGroup']:
            suffix = suffix if suffix else default_suffix
            image['location'] = image_def['location']
            image['tempResourceGroup'] = f'{image["gallery"]["name"]}-{image["name"]}-{suffix}'

        log.info(f'Image {image["name"]} properties:')
        for line in json.dumps(image, indent=4).splitlines():
            log.info(line)

        validate(image)

    return image


def all(gallery, common=None, suffix=None, ensure_azure=False) -> list:
    common = common if common else get_common()
    names = image_names()
    for name in names:
        log.warning(f'Getting image {name}')
    images = [get(i, gallery, common, suffix, ensure_azure) for i in image_names()]
    return images


def image_names() -> list:
    names = []

    # walk the images directory and find all the image.yml/image.yaml files
    for dirpath, dirnames, files in os.walk(images_root):
        # os.walk includes the root directory (i.e. repo/images) so we need to skip it
        if not images_root.samefile(dirpath) and Path(dirpath).parent.samefile(images_root):
            names.append(Path(dirpath).name)

    return names


if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='generates the matrix for fan out builds in github actions.')
    parser.add_argument('--images', '-i', nargs='*', help='names of images to include. if not specified all images will be')
    parser.add_argument('--github', action='store_true', help='if specified, set output variables for github actions')

    args = parser.parse_args()
    from gallery import get as get_gallery

    gallery = get_gallery()
    common = get_common()

    # images = [get(i, gallery, common) for i in args.images] if args.images else all(gallery, common)
    images = [get(i, gallery, common, 'suffix', ensure_azure=True) for i in args.images] if args.images else all(gallery, common, 'suffix', ensure_azure=True)
    import json
    for image in images:
        print(json.dumps(image, indent=4))

    if args.github or os.environ.get('GITHUB_ACTIONS', False):
        import json
        print("::set-output name=images::{}".format(json.dumps({'include': images})))
        print("::set-output name=build::{}".format(len(images) > 0))
