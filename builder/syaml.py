# ------------------------------------
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
# ------------------------------------

import os
import sys
from pathlib import Path

import loggers

log = loggers.getLogger(__name__)


def error_exit(message):
    log.error(message)
    sys.exit(message)


def get_file(dir, file, required=True):
    '''Get the path to a yaml or yml file in a directory'''
    if not os.path.isdir(dir):
        if required:
            error_exit(f'Directory for yaml/yml {file} not found at {dir}')
        return None

    yaml = os.path.isfile(os.path.join(dir, f'{file}.yaml'))
    yml = os.path.isfile(os.path.join(dir, f'{file}.yml'))

    if not yaml and not yml:
        if required:
            error_exit(f'File {file}.yaml or {file}.yml not found in {dir}')
        return None

    if yaml and yml:
        error_exit(f'Found both {file}.yaml and {file}.yml in {dir} of repository. only one {file} yaml file allowed')

    dir_path = dir if isinstance(dir, Path) else Path(dir)
    file_path = dir_path / f'{file}.yaml' if yaml else dir_path / f'{file}.yml'

    return file_path


def validate(path, obj, required=None, allowed=None):
    '''validate the yaml object against the required and allowed keys'''
    if required:
        for key in required:
            if key not in obj:
                error_exit(f'yaml file at {path} is missing required property {key}')
            if not obj[key]:
                error_exit(f'yaml file at {path} is missing a value for required property {key}')

    if allowed:
        for key in obj:
            if key not in allowed:
                error_exit(f'yaml file at {path} contains an invalid property {key}')

    return True


def parse(path, required=None, allowed=None) -> dict:
    '''simple yaml parser, only supports a single level of nesting and arrays that use the '-' notation'''
    obj = {}
    with open(path, 'r') as yaml:
        parent_key = None

        for line in yaml:
            if line.strip() == '' or line.lstrip().startswith('#'):  # ignore empty lines and comments
                continue

            if line.lstrip().startswith('-'):  # array item
                if not parent_key:
                    error_exit(f'array item found without parent key\n{line}')

                if parent_key not in obj:
                    obj[parent_key] = []

                item = line.split('-')[1].strip()

                if ':' in item:  # object array (ex: - name: value)
                    s_key, s_value = [s.strip() for s in item.split(':')]
                    # if the array is empty or the last item in the array already has the key, add a new item
                    if len(obj[parent_key]) == 0 or s_key in obj[parent_key][-1]:
                        obj[parent_key].append({})

                    obj[parent_key][-1][s_key] = s_value
                else:  # simple array (ex: - value)
                    obj[parent_key].append(item)

            elif ':' in line:  # key: value || key: { ... } || key: [ ... ]

                key, value = [s.strip() for s in line.split(':')]

                if line.replace(line.lstrip(), '') != '':  # key is indented (property of an object)

                    if not parent_key:
                        error_exit(f'line appears to be a property of an object but no key found in previous lines\n{line}')
                    if not value:
                        error_exit(f'line appears to be a property of an object but no value found\n{line}')

                    if parent_key not in obj:
                        obj[parent_key] = {}

                    if isinstance(obj[parent_key], list):
                        obj[parent_key][-1][key] = value
                    elif isinstance(obj[parent_key], dict):
                        obj[parent_key][key] = value

                elif not value:  # object or array, save the key for later
                    parent_key = key

                else:  # simple key/value pair
                    obj[key] = value
                    parent_key = None

            else:
                error_exit(f'line does not contain a colon or is misformatted\n{line}')

    validate(path, obj, required, allowed)

    return obj
