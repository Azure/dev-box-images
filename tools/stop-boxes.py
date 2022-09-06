import argparse
import json
import shutil
import subprocess
import sys
from uuid import UUID

RESOURCE_NOT_FOUND = 'Code: ResourceNotFound'


def error_exit(message):
    print(f'ERROR: {message}')
    sys.exit(message)


def _is_valid_uuid(uuid_to_test, version=4):
    '''Check if uuid_to_test is a valid UUID.'''
    try:
        uuid_obj = UUID(uuid_to_test, version=version)
    except ValueError:
        return False
    return str(uuid_obj) == uuid_to_test


def _parse_az_command(command):
    '''Parse an az command into a list of arguments for subprocess.run'''
    if isinstance(command, list):
        args = command
    elif isinstance(command, str):
        args = command.split()
    else:
        raise ValueError(f'az command must be a string or list, not {type(command)}')

    az = shutil.which('az')
    if args[0] == 'az':
        args.pop(0)
    if args[0] != az:
        args = [az] + args

    return args


def _az(command, log_command=True):
    '''Run an az cli command and return the result as a dict or None if the resource was not found.'''
    args = _parse_az_command(command)
    try:
        if log_command:
            print(f'Running az cli command: {" ".join(args)}')
        proc = subprocess.run(args, capture_output=True, check=True, text=True)
        return None if proc.returncode == 0 and not proc.stdout else json.loads(proc.stdout)
    except subprocess.CalledProcessError as e:
        if e.stderr and RESOURCE_NOT_FOUND in e.stderr:
            return None
        error_exit(e.stderr if e.stderr else 'azure cli command failed')
    except json.decoder.JSONDecodeError:
        error_exit('{}: {}'.format('Could not decode response json', proc.stderr if proc.stderr else proc.stdout if proc.stdout else proc))


parser = argparse.ArgumentParser()
parser.add_argument('--dev-center', '-dc', dest='devcenter', required=True, help='the devcenter to operate on')
parser.add_argument('--projects', '-p', nargs='*', help='names of projects to stop running boxes. if not specified all projects will be included')
parser.add_argument('--pools', nargs='*', help='names of pools to stop running boxes. if not specified all pools will be included')
parser.add_argument('--users', '-u', nargs='*', help='ids of users to stop running boxes. if not specified all users will be included')
args = parser.parse_args()

devcenter = args.devcenter

project_names = [p for p in args.projects] if args.projects else None
pool_names = [p for p in args.pools] if args.pools else None
user_ids = [u for u in args.users] if args.users else None

if user_ids:
    for user_id in user_ids:
        if not _is_valid_uuid(user_id):
            error_exit(f"'{user_id}' is not a valid uuid")

# get all projects in the devcenter
print(f'Getting projects in DevCenter: {devcenter} ...')
projects = _az(f'devcenter dev project list -dc {devcenter}', log_command=False)

# make sure we got a list of projects
if not projects or len(projects) == 0:
    print(f'WARNING: No projects found in devcenter: {devcenter}. Make sure you have at least Reader role on the projects.')
    sys.exit(0)

# filter projects by name (if specified)
if project_names:
    projects = [p for p in projects if p['name'] in project_names]
    # ensure we have at least one project
    if len(projects) == 0:
        print(f'No projects found in devcenter {devcenter} matching names: {project_names}. Make sure you typed the names correctly and have at least Reader role on the projects.')
        sys.exit(1)
    # ensure we found all the projects we were looking for
    for name in project_names:
        if name not in [p['name'] for p in projects]:
            print(f'No projects found in devcenter {devcenter} matching name: {name}. Make sure you typed the name correctly and have at least Reader role on the project.')
            sys.exit(1)

print(f' found {len(projects)} {"project" if len(projects) == 1 else "projects"}: {[n["name"] for n in projects]}')

# would be ideal to create an odata query based in the projects/pools/users
# but it doesn't look like the --filter argment is respected by the dataplane
# get all dev-boxes in the devcenter
all_boxes = _az(f'devcenter dev dev-box list -dc {devcenter}', log_command=False)

if not all_boxes or len(all_boxes) == 0:
    print(f'WARNING: No boxes found in devcenter: {devcenter}. Make sure you have the DevCenter Project Admin role on the projects.')
    sys.exit(0)

for project in projects:
    print('')
    print(f'Getting boxes in {project["name"]} ...')

    # filter boxes for the project
    project_boxes = [b for b in all_boxes if b['projectName'] == project['name']]

    if not project_boxes or len(project_boxes) == 0:
        print(f'WARNING: No boxes found in project: {project["name"]}. If this is incorrect, make sure you have the DevCenter Project Admin role on the project.')
        continue

    # filter boxes by users (if specified)
    if user_ids:
        project_boxes = [b for b in project_boxes if b['user'] in user_ids]
        if len(project_boxes) == 0:
            print(f' no boxes found matching users: {user_ids}')
            continue

    # filter boxes by pools (if specified)
    if pool_names:
        project_boxes = [b for b in project_boxes if b['poolName'] in pool_names]
        if len(project_boxes) == 0:
            print(f' no boxes found matching pools: {pool_names}')
            continue

    corect_grammer = " matching specified pools/users" if user_ids or pool_names else ""
    print(f' found {len(project_boxes)} {"box" if len(project_boxes) == 1 else "boxes"}{corect_grammer}: {[b["name"] for b in project_boxes]}')

    not_running = [b for b in project_boxes if b['powerState'].lower() != 'running']
    if not_running and len(not_running) > 0:
        corect_grammer = "box because it isn't" if len(not_running) == 1 else "boxes because they aren't"
        print(f' skipping {len(not_running)} {corect_grammer} running: {[b["name"] for b in not_running]}')

    # filter out boxes that are not running
    project_boxes = [b for b in project_boxes if b['powerState'].lower() == 'running']

    # if we still have boxes to stop, stop them
    if len(project_boxes) > 0:
        print(f' stopping {len(project_boxes)} {"box" if len(project_boxes) == 1 else "boxes"}')

        for box in project_boxes:
            print(f' stopping {box["name"]}...')
            _az(f'devcenter dev dev-box stop -dc {devcenter} --project {box["projectName"]} --user-id {box["user"]} -n {box["name"]}', log_command=False)
            print(f' {box["name"]} stopped')
        print(f' done')

print('')
print('Done')
