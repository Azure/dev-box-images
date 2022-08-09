import os
from pathlib import Path

import syaml

this_path = Path(__file__).resolve().parent
repo_root = this_path.parent

is_github = os.environ.get('GITHUB_ACTIONS', False)


def log_message(msg):
    print(f'[tools/gallery] {msg}')


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


def get():
    '''
    ### Summary
    Looks for a 'gallery.yaml' or 'gallery.yml' file in the root of the repository and returns a dictionary of the contents.

    ### Returns:
    A dictionary of the contents of the gallery.yaml file.
    '''

    gallery_yaml = os.path.isfile(os.path.join(repo_root, 'gallery.yaml'))
    gallery_yml = os.path.isfile(os.path.join(repo_root, 'gallery.yml'))

    if not gallery_yaml and not gallery_yml:
        log_error('gallery.yaml or gallery.yml not found in the root of the repository')

    if gallery_yaml and gallery_yml:
        log_error("found both 'gallery.yaml' and 'gallery.yml' in root of repository. only one gallery yaml file allowed")

    gallery_path = repo_root / 'gallery.yaml' if gallery_yaml else repo_root / 'gallery.yml'

    gallery = syaml.parse(gallery_path)

    if 'name' not in gallery or not gallery['name']:
        log_error("gallery.yaml/gallery.yml must have a 'name' property with a value")

    if 'resourceGroup' not in gallery or not gallery['resourceGroup']:
        log_error("gallery.yaml/gallery.yml must have a 'resourceGroup' property with a value")

    return gallery
