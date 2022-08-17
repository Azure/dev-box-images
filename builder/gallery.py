import os
import sys
from pathlib import Path

import loggers
import syaml

log = loggers.getLogger(__name__)

in_builder = os.environ.get('ACI_IMAGE_BUILDER', False)

repo = Path('/mnt/repo') if in_builder else Path(__file__).resolve().parent.parent


def error_exit(message):
    log.error(message)
    sys.exit(message)


def get():

    gallery_yaml = os.path.isfile(os.path.join(repo, 'gallery.yaml'))
    gallery_yml = os.path.isfile(os.path.join(repo, 'gallery.yml'))

    if not gallery_yaml and not gallery_yml:
        error_exit('gallery.yaml or gallery.yml not found in the root of the repository')

    if gallery_yaml and gallery_yml:
        error_exit("found both 'gallery.yaml' and 'gallery.yml' in root of repository. only one gallery yaml file allowed")

    gallery_path = repo / 'gallery.yaml' if gallery_yaml else repo / 'gallery.yml'

    gallery = syaml.parse(gallery_path)

    if 'name' not in gallery or not gallery['name']:
        error_exit("gallery.yaml/gallery.yml must have a 'name' property with a value")

    if 'resourceGroup' not in gallery or not gallery['resourceGroup']:
        error_exit("gallery.yaml/gallery.yml must have a 'resourceGroup' property with a value")

    return gallery
