import argparse
import os
from pathlib import Path

import azure
import syaml

this_path = Path(__file__).resolve().parent
repo_root = this_path.parent
images_root = repo_root / 'images'

required_properties = ['publisher', 'offer', 'sku', 'version', 'os', 'replicaLocations']


def validate(image):
    for required_property in required_properties:
        if required_property not in image:
            print(f'::error:: image.yaml for {image["name"]} is missing required property {required_property}')
            raise ValueError(f'image.yaml for {image["name"]} is missing required property {required_property}')
        if not image[required_property]:
            print(f'::error:: image.yaml for {image["name"]} is missing a value for required property {required_property}')
            raise ValueError(f'image.yaml for {image["name"]} is missing a value for required property {required_property}')


def get(image_name) -> dict:
    '''
    ### Summary
    Looks for a directory containing a 'image.yaml' or 'image.yml' file in the /images direcory and returns a dictionary of the contents.

    ### Returns:
    A dictionary of the contents of the image.yaml file.

    #### example:
    ```
    {
      'description': 'Windows 11 Enterprise + M365 Apps + VSCode',
      'publisher': 'Contoso',
      'offer': 'DevBox',
      'sku': 'win11-vscode',
      'version': '1.0.25',
      'os': 'Windows',
      'replicaLocations': [
        'eastus',
        'westeurope'
      ],
      'name': 'VSCodeBox',
      'path': '/Users/user/GitHub/user/devbox-images/images/VSCodeBox',
      'gallery': {
        'name': 'Contoso',
        'resourceGroup': 'Compute-Gallery'
      },
      'location': 'eastus',
      'tempResourceGroup': 'Contoso-VSCodeBox-20220722190624'
    }
    ```
    '''

    image_dir = images_root / image_name

    if not os.path.isdir(image_dir):
        print(f'::error:: directory for image {image_name} not found at {image_dir}')
        raise ValueError(f'directory for image {image_name} not found at {image_dir}')

    image_yaml = os.path.isfile(os.path.join(image_dir, 'image.yaml'))
    image_yml = os.path.isfile(os.path.join(image_dir, 'image.yml'))

    if not image_yaml and not image_yml:
        print(f'::error:: image.yaml or image.yml not found {image_dir}')
        raise ValueError(f'image.yaml or image.yml not found {image_dir}')

    if image_yaml and image_yml:
        print(f"::error:: found both 'image.yaml' and 'image.yml' in {image_dir} of repository. only one image yaml file allowed")
        raise ValueError(f"found both 'image.yaml' and 'image.yml' in {image_dir} of repository. only one image yaml file allowed")

    image_path = image_dir / 'image.yaml' if image_yaml else image_dir / 'image.yml'

    image = syaml.parse(image_path)
    image['name'] = Path(image_dir).name
    image['path'] = f'{image_dir}'

    validate(image)

    return image


def all() -> list:
    '''
    ### Summary
    Looks for a directories containing a 'image.yaml' or 'image.yml' file in the /images direcory and returns a list of dictionaries of the contents.

    ### Returns:
    A dictionary of the contents of the image.yaml file.

    #### example:
    ```
    [
      {
        'description': 'Windows 11 Enterprise + M365 Apps + VSCode',
        'publisher': 'Contoso',
        'offer': 'DevBox',
        'sku': 'win11-vscode',
        'version': '1.0.25',
        'os': 'Windows',
        'replicaLocations': [
          'eastus',
          'westeurope'
        ],
        'name': 'VSCodeBox',
        'path': '/Users/user/GitHub/user/devbox-images/images/VSCodeBox',
        'gallery': {
          'name': 'Contoso',
          'resourceGroup': 'Compute-Gallery'
        },
        'location': 'eastus',
        'tempResourceGroup': 'Contoso-VSCodeBox-20220722190624'
      }
    ]
    ```
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

    print("::set-output name=images::{}".format(json.dumps({'include': imgs})))
    print("::set-output name=build::{}".format(len(imgs) > 0))


if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='builds a single image. assumes the image is already using the build.py without the --packer | -p arg.')
    parser.add_argument('--images', '-i', nargs='*', help='names of images to build. if not specified all images will be')

    args = parser.parse_args()

    main(args.images)
