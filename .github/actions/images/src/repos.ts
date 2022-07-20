import * as core from '@actions/core';

// import { getKeyVaultSecret } from './azure';
import { Image, Repo } from './types';

const isGitHubUrl = (url: string): boolean => url.toLowerCase().includes('github.com');
const isDevOpsUrl = (url: string): boolean => url.toLowerCase().includes('dev.azure.com') || url.toLowerCase().includes('visualstudio.com');

// examples:
// https://github.com/colbylwilliams/devbox-images.git
// git@github.com:colbylwilliams/devbox-images.git
const parseGitHubUrl = async (repo: Repo) => {

    let url = repo.url;

    url = url.toLowerCase().replace('git@', 'https://').replace('github.com:', 'github.com/');

    // remove .git extension
    if (url.endsWith('.git'))
        url = url.slice(0, url.length - 4);

    const parts = url.split('/');
    const index = parts.findIndex(p => p.includes('github.com'));

    if (index === -1 || parts.length < index + 3)
        core.setFailed(`Invalid GitHub repository url: ${repo.url}`);

    repo.url = url;
    repo.org = parts[index + 1];
    repo.repo = parts[index + 2];

    repo.cloneUrlTemplate = url.replace('https://github.com', 'https://{0}@github.com') + '.git';
    // const secret = await getKeyVaultSecret(repo.secret) ?? '';
    // repo.cloneUrl = url.replace('https://github.com', `https://${secret}@github.com`) + '.git';
};

// examples:
// https://dev.azure.com/colbylwilliams/MyProject/_git/devbox-images
// https://colbylwilliams.visualstudio.com/DefaultCollection/MyProject/_git/devbox-images
// https://colbylwilliams@dev.azure.com/colbylwilliams/MyProject/_git/devbox-images
const parseDevOpsUrl = (repo: Repo) => {

    let url = repo.url;

    url = url.toLowerCase().replace('git@ssh', 'https://').replace(':v3/', '/');

    // remove .git extension
    if (url.endsWith('.git'))
        url = url.slice(0, url.length - 4);

    const parts = url.split('/');
    let index = parts.findIndex(p => p.includes('dev.azure.com') || p.includes('visualstudio.com'));

    if (index === -1)
        core.setFailed(`Invalid Azure DevOps repository url: ${repo.url}`);

    const gitIndex = parts.indexOf('_git');

    if (gitIndex !== -1)
        parts.splice(gitIndex, 1);
    else {
        const last = parts[parts.length - 1];
        url = url.replace(`/${last}`, `/_git/${last}`);
    }

    if (parts[index].includes('dev.azure.com'))
        ++index;

    if (parts.length < index + 3)
        core.setFailed(`Invalid Azure DevOps repository url: ${repo.url}`);

    repo.url = url;
    repo.org = parts[index].replace('visualstudio.com', '');
    repo.project = parts[index + 1];
    repo.repo = parts[index + 2];
    // repo.cloneUrl
};

const parseRepoUrl = async (repo: Repo) => {
    if (isGitHubUrl(repo.url))
        await parseGitHubUrl(repo);
    else if (isDevOpsUrl(repo.url))
        parseDevOpsUrl(repo);
    else
        core.setFailed(`Invalid repository url: ${repo.url}\nOnly GitHub and Azure DevOps git repositories are supported. Generic git repositories are not supported.`);
};

export async function parseRepos(image: Image) {

    const repos: Repo[] = [];

    if (image.repos) {
        for (const i in image.repos) {
            const repo = image.repos[i];
            await parseRepoUrl(repo);
            repos.push(repo);
        }
    }

    image.repos = repos;
};