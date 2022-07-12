const fs = require('fs/promises');
const yaml = require('js-yaml');

module.exports = async ({ github, context, core, glob, exec, }) => {

    const NOT_FOUND_CODE = 'Code: ResourceNotFound';

    const { galleryResourceGroup, galleryName } = process.env;
    const workspace = process.env.GITHUB_WORKSPACE;

    core.startGroup(`Checking for changed files`);

    const compare = await github.rest.repos.compareCommitsWithBasehead({
        owner: context.repo.owner,
        repo: context.repo.repo,
        basehead: `${context.payload.before}...${context.payload.after}`
    });

    const changes = compare.data.files.map(f => f.filename);

    core.info(`Found ${changes.length} changed files`);
    for (const c of changes) {
        core.info(`- ${c}`);
    }

    core.endGroup();

    const patterns = ['**/image.yml', '**/image.yaml']
    const globber = await glob.create(patterns.join('\n'));
    const files = await globber.glob();

    let include = [];

    for (const file of files) {

        const imageName = file.split('/').slice(-2)[0];

        core.startGroup(`Processing image config ${imageName} : ${file}`);

        const contents = await fs.readFile(file, 'utf8');
        const image = yaml.load(contents);

        image.name = imageName;
        image.galleryName = galleryName;
        image.galleryResourceGroup = galleryResourceGroup;

        image.source = file.split('/image.y')[0];
        image.path = image.source.split(`${workspace}/`)[1];
        image.changed = changes.some(change => change.startsWith(image.path) || change.startsWith(`scripts/`));

        image.locations = JSON.stringify(image.locations);

        const useBuildGroup = image.buildResourceGroup && image.buildResourceGroup.length > 0;

        image.tempResourceGroup = useBuildGroup ? '' : `${image.galleryName}-${image.name}-${context.runNumber}`;

        image.resolvedResourceGroup = useBuildGroup ? image.buildResourceGroup : image.tempResourceGroup;

        if (!image.version) {
            core.warning(`Skipping ${image.name} because of missing version information`);
        } else {

            const imgDefShowCmd = [
                'sig', 'image-definition', 'show',
                '--only-show-errors',
                '-g', image.galleryResourceGroup,
                '-r', image.galleryName,
                '-i', image.name
            ];

            core.info(`Checking if image definition exists for ${image.name}`);
            const imgDefShow = await exec.getExecOutput('az', imgDefShowCmd, { silent: true, ignoreReturnCode: true });

            if (imgDefShow.exitCode === 0) {

                core.info(`Found existing image definition for ${image.name}`);
                const img = JSON.parse(imgDefShow.stdout);
                image.location = useBuildGroup ? '' : img.location;

                // image definition exists, check if the version already exists

                const imgVersionShowCmd = [
                    'sig', 'image-version', 'show',
                    '--only-show-errors',
                    '-g', image.galleryResourceGroup,
                    '-r', image.galleryName,
                    '-i', image.name,
                    '-e', image.version
                ];

                core.info(`Checking if image version ${image.version} already exists for ${image.name}`);
                const imgVersionShow = await exec.getExecOutput('az', imgVersionShowCmd, { silent: true, ignoreReturnCode: true });

                if (imgVersionShow.exitCode !== 0) {
                    if (imgVersionShow.stderr.includes(NOT_FOUND_CODE)) {

                        // image version does not exist, add it to the list of images to create
                        core.info(`Image version ${image.version} does not exist for ${image.name}. Creating`);
                        include.push(image);
                    } else {

                        // image version exists, but we don't know what happened
                        core.setFailed(`Failed to check for existing image version ${image.version} for ${image.name} \n ${imgVersionShow.stderr}`);
                    }

                } else if (image.changed) {

                    // image version already exists, but the image source has changed, so we the version number needs to be updated
                    core.setFailed(`Image version ${image.version} already exists for ${image.name} but image definition files changed. Please update the version number or delete the image version and try again.`);
                } else {

                    // image version already exists, and the image source has not changed, so we don't need to do anything
                    core.info(`Image version ${image.version} already exists for ${image.name} and image definition is unchanged. Skipping`);
                }

            } else if (imgDefShow.stderr.includes(NOT_FOUND_CODE)) {

                // image definition does not exist, create it and skip the version check

                core.info(`Image definition for ${image.name} does not exist in gallery ${image.galleryName}`);

                const imgDefCreateCmd = [
                    'sig', 'image-definition', 'create',
                    '--only-show-errors',
                    '-g', image.galleryResourceGroup,
                    '-r', image.galleryName,
                    '-i', image.name,
                    '-p', image.publisher,
                    '-f', image.offer,
                    '-s', image.sku,
                    '--os-type', image.os,
                    // '--os-state', 'Generalized', (default)
                    '--description', image.description,
                    '--hyper-v-generation', 'V2',
                    '--features', 'SecurityType=TrustedLaunch'
                ];

                core.info(`Creating new image definition for ${image.name}`);
                const imgDefCreate = await exec.getExecOutput('az', imgDefCreateCmd, { silent: true, ignoreReturnCode: true });

                if (imgDefCreate.exitCode === 0) {

                    core.info(`Successfully created image definition for ${image.name}`);
                    const img = JSON.parse(imgDefCreate.stdout);
                    image.location = useBuildGroup ? '' : img.location;

                } else {
                    core.setFailed(`Failed to create image definition for ${image.name} \n ${imgDefCreate.stderr}`);
                }

            } else {
                core.setFailed(`Failed to get image definition for ${image.name} \n ${imgDefShow.stderr}`);
            }


        }

        core.endGroup();
    };


    if (include.length > 0) {

        const rows = [[
            { header: true, data: 'Name' },
            { header: true, data: 'Version' },
            { header: true, data: 'Publisher' },
            { header: true, data: 'Offer' },
            { header: true, data: 'SKU' },
            { header: true, data: 'OS' },
            { header: true, data: 'Resource Group' },
        ]];

        for (const i of include) {
            rows.push([
                i.name,
                i.version,
                i.publisher,
                i.offer,
                i.sku,
                i.os,
                i.resolvedResourceGroup,
            ]);
        }

        await core.summary
            .addHeading('Images prepared for update', 3)
            .addTable(rows).write();

    } else {
        await core.summary.addHeading('No images were built', 4).write();
    }

    const matrix = {
        include: include
    };

    core.setOutput('matrix', JSON.stringify(matrix));
    core.setOutput('build', matrix.include.length > 0);
};