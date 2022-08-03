import * as core from '@actions/core';
import * as github from '@actions/github';
import * as glob from '@actions/glob';
import { PushEvent } from '@octokit/webhooks-types';
import * as fs from 'fs/promises';
import * as yaml from 'js-yaml';

import * as path from 'path';
import { parseRepos } from './repos';
import { Gallery, Image } from './types';

const workspace = process.env.GITHUB_WORKSPACE;

const parseImage = async (gallery: Gallery, file: string): Promise<Image> => {

    const imageName = file.split(path.sep).slice(-2)[0];

    core.startGroup(`Processing image config ${imageName} : ${file}`);

    const contents = await fs.readFile(file, 'utf8');
    const image = yaml.load(contents) as Image;

    image.name = imageName;
    image.galleryName = gallery.name;
    image.galleryResourceGroup = gallery.resourceGroup;

    image.source = file.split(`${path.sep}image.y`)[0]; // ex: /home/runner/work/devbox-images/devbox-images/images/VSCodeBox
    image.path = image.source.split(`${workspace}${path.sep}`)[1]; // ex: images/VSCodeBox/image.yml

    image.useBuildGroup = !!image.buildResourceGroup && image.buildResourceGroup.length > 0;

    image.tempResourceGroup = image.useBuildGroup ? '' : `${image.galleryName}-${image.name}-${github.context.runNumber}`;

    image.resolvedResourceGroup = image.useBuildGroup ? image.buildResourceGroup! : image.tempResourceGroup!;

    parseRepos(image);

    core.endGroup();

    return image;
};

const getChanges = async (): Promise<string[] | undefined> => {

    const context = github.context;

    if (context.eventName === 'push') {

        const push = context.payload as PushEvent;

        if (!push.created) {
            core.startGroup(`Checking for changed files`);

            const token = core.getInput('github-token', { required: true });
            const octokit = github.getOctokit(token);

            const compare = await octokit.rest.repos.compareCommitsWithBasehead({
                ...context.repo,
                basehead: `${push.before}...${push.after}`
            });

            const changes = compare?.data?.files?.map(f => f.filename);

            core.info(`Found ${changes?.length ?? 0} changed files`);
            if (changes)
                for (const c of changes)
                    core.info(`- ${c}`);

            core.endGroup();

            return changes;
        }
    }

    return undefined;
};

export async function getImages(gallery: Gallery): Promise<Image[]> {

    const patterns = ['**/image.yml', '**/image.yaml'];
    const globber = await glob.create(patterns.join('\n'));
    const files = await globber.glob();

    const images: Image[] = [];

    for (const file of files) {
        const image = await parseImage(gallery, file);
        if (image.version)
            images.push(image);
        else
            core.warning(`Skipping ${image.name} because of missing version information`);
    }

    const changes = await getChanges();

    // rebuild if any changes were found in the image directory or the scripts directory
    // changes will be undefined if the event is not a push, or if the push created the branch
    const changeAll = changes === undefined || changes.some(c => c.startsWith(`scripts/`));

    images.forEach(image => {
        image.changed = changeAll || changes.some(change => change.startsWith(image.path.replace(/\\/gm, '\/')));
    });

    return images;
};