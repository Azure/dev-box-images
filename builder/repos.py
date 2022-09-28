# ------------------------------------
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
# ------------------------------------

def _is_github(url) -> bool:
    return 'github.com' in url.lower()


def _is_devops(url) -> bool:
    return 'dev.azure.com' in url.lower() or 'visualstudio.com' in url.lower()


def _parse_github_url(url) -> dict:
    '''Parse a GitHub repository git url into its parts'''
    # examples:
    # git://github.com/codertocat/hello-world.git
    # https://github.com/colbylwilliams/devbox-images.git
    # git@github.com:colbylwilliams/devbox-images.git

    if not _is_github(url):
        raise ValueError(f'{url} is not a valid GitHub repository url')

    url = url.lower().replace('git@', 'https://').replace('git://', 'https://').replace('github.com:', 'github.com/')

    if url.endswith('.git'):
        url = url[:-4]

    parts = url.split('/')

    index = next((i for i, part in enumerate(parts) if 'github.com' in part), -1)

    if index == -1 or len(parts) < index + 3:
        raise ValueError(f'{url} is not a valid GitHub repository url')

    repo = {
        'provider': 'github',
        'url': url,
        'org': parts[index + 1],
        'repo': parts[index + 2]
    }

    return repo


def _parse_devops_url(url) -> dict:
    '''Parse an Azure DevOps repository git url into its parts'''
    # examples:
    # https://dev.azure.com/colbylwilliams/MyProject/_git/devbox-images
    # https://colbylwilliams.visualstudio.com/DefaultCollection/MyProject/_git/devbox-images
    # https://colbylwilliams@dev.azure.com/colbylwilliams/MyProject/_git/devbox-images

    if not _is_devops(url):
        raise ValueError(f'{url} is not a valid Azure DevOps respository url')

    url = url.lower().replace('git@ssh', 'https://').replace(':v3/', '/')

    if '@dev.azure.com' in url:
        url = 'https://dev.azure.com' + url.split('@dev.azure.com')[1]

    if url.endswith('.git'):
        url = url[:-4]

    parts = url.split('/')

    index = next((i for i, part in enumerate(parts) if 'dev.azure.com' in part or 'visualstudio.com' in part), -1)

    if index == -1:
        raise ValueError(f'{url} is not a valid Azure DevOps respository url')

    if '_git' in parts:
        parts.pop(parts.index('_git'))
    else:
        last = parts[-1]
        url = url.replace(f'/{last}', f'/_git/{last}')

    if 'dev.azure.com' in parts[index]:
        index += 1

    if len(parts) < index + 3:
        raise ValueError(f'{url} is not a valid Azure DevOps respository url')

    repo = {
        'provider': 'devops',
        'url': url,
        'org': parts[index].replace('.visualstudio.com', '')
    }

    if parts[index + 1] == 'defaultcollection':
        index += 1

    repo['project'] = parts[index + 1]
    repo['repo'] = parts[index + 2]

    return repo


def parse_url(url) -> dict:
    '''Parse a repository git url into its parts. Supports GitHub and Azure DevOps'''

    if _is_github(url):
        return _parse_github_url(url)

    if _is_devops(url):
        return _parse_devops_url(url)

    raise ValueError(f'{url} is not a valid repository url')


if __name__ == '__main__':

    import json

    test_urls = [
        'git://github.com/colbylwilliams/devbox-images.git',
        'https://github.com/colbylwilliams/devbox-images.git',
        'git@github.com:colbylwilliams/devbox-images.git',
        'https://dev.azure.com/colbylwilliams/MyProject/_git/devbox-images',
        'https://colbylwilliams.visualstudio.com/DefaultCollection/MyProject/_git/devbox-images',
        'https://user@dev.azure.com/colbylwilliams/MyProject/_git/devbox-images'
    ]

    print('')
    for test in test_urls:
        repo = parse_url(test)
        if repo['provider'] not in ['github', 'devops']:
            raise ValueError(f'{repo["provider"]} is not a valid provider')
        if repo['org'] != 'colbylwilliams':
            raise ValueError(f'{repo["org"]} is not a valid organization')
        if repo['provider'] == 'devops' and repo['project'] != 'myproject':
            raise ValueError(f'{repo["project"]} is not a valid project')
        if repo['repo'] != 'devbox-images':
            raise ValueError(f'{repo["repo"]} is not a valid repository')
        if '@' in repo['url']:
            raise ValueError(f'{repo["url"]} should not contain an @ symbol')
        print(test)
        print(json.dumps(repo, indent=4))
    print('')
