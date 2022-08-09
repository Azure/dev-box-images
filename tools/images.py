import argparse
import os
from pathlib import Path

import syaml

this_path = Path(__file__).resolve().parent
repo_root = this_path.parent
images_root = repo_root / 'images'

required_properties = ['publisher', 'offer', 'sku', 'version', 'os', 'replicaLocations', 'builder']

is_github = os.environ.get('GITHUB_ACTIONS', False)


def log_message(msg):
    print(f'[tools/images] {msg}')


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


def validate(image):
    for required_property in required_properties:
        if required_property not in image:
            log_error(f'image.yaml for {image["name"]} is missing required property {required_property}')
        if not image[required_property]:
            log_error(f'image.yaml for {image["name"]} is missing a value for required property {required_property}')
    if image['builder'] not in ['packer', 'azure']:
        log_error(f'image.yaml for {image["name"]} has an invalid builder property value {image["builder"]}')


def get(image_name) -> dict:
    '''
    ### Summary
    Looks for a directory containing a 'image.yaml' or 'image.yml' file in the /images direcory and returns a dictionary of the contents.

    ### Returns:
    A dictionary of the contents of the image.yaml file.
    '''

    image_dir = images_root / image_name

    if not os.path.isdir(image_dir):
        log_error(f'directory for image {image_name} not found at {image_dir}')

    image_yaml = os.path.isfile(os.path.join(image_dir, 'image.yaml'))
    image_yml = os.path.isfile(os.path.join(image_dir, 'image.yml'))

    if not image_yaml and not image_yml:
        log_error(f'image.yaml or image.yml not found {image_dir}')

    if image_yaml and image_yml:
        log_error(f"found both 'image.yaml' and 'image.yml' in {image_dir} of repository. only one image yaml file allowed")

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

    validate(image)

    return image


def all() -> list:
    '''
    ### Summary
    Looks for a directories containing a 'image.yaml' or 'image.yml' file in the /images direcory and returns a list of dictionaries of the contents.

    ### Returns:
    A list of dictionaries with the contents of the image.yaml files.
    '''
    images = []

    # walk the images directory and find all the image.yml/image.yaml files
    for dirpath, dirnames, files in os.walk(images_root):
        # os.walk includes the root directory (i.e. repo/images) so we need to skip it
        if not images_root.samefile(dirpath) and Path(dirpath).parent.samefile(images_root):
            image = get(Path(dirpath).name)
            images.append(image)

    return images


def main(images):
    import json
    imgs = [get(i) for i in images] if images else all()

    if is_github:
        print("::set-output name=images::{}".format(json.dumps({'include': imgs})))
        print("::set-output name=build::{}".format(len(imgs) > 0))


if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='generates the matrix for fan out builds in github actions.')
    parser.add_argument('--images', '-i', nargs='*', help='names of images to include. if not specified all images will be')

    args = parser.parse_args()

    main(args.images)
