const fs = require('fs/promises');
const yaml = require('js-yaml');


module.exports = async ({ github, context, core, glob, exec, }) => {

    const { resourceGroup, galleryName } = process.env;

    let matrix = {
        include: []
    };

    const patterns = ['**/image.yml', '**/image.yaml']
    const globber = await glob.create(patterns.join('\n'));
    const files = await globber.glob();

    const compare = await github.rest.repos.compareCommitsWithBasehead({
        owner: context.repo.owner,
        repo: context.repo.repo,
        basehead: `${context.payload.before}...${context.payload.after}`
    });

    // core.info(`Compare response: ${JSON.stringify(compare, null, 2)}`);

    const changes = compare.data.files.map(f => f.filename);

    // core.info(`Context: ${JSON.stringify(context, null, 2)}`);
    // core.info(`github: ${JSON.stringify(github, null, 2)}`);

    core.info('CHANGES');
    for (const change of changes) {
        core.info(`... ${change}`);
    }

    const workspace = process.env.GITHUB_WORKSPACE;

    core.info(`WORKSPACE ${workspace}`);

    for (const file of files) {
        core.info(`Found image configuration file at ${file}`);

        // Get image name from folder
        const imageName = file.split('/').slice(-2)[0];

        const contents = await fs.readFile(file, 'utf8');
        const image = yaml.load(contents);


        image.gallery = galleryName;
        image.name = imageName;


        image.source = file.split('/image.y')[0];
        image.path = image.source.split(`${workspace}/`)[1];
        image.changed = changes.some(change => change.startsWith(image.path));

        // core.info('  ');
        // core.info(`SOURCE: ${image.source}`);
        // core.info(`PATH: ${image.path}`);
        // core.info(`CHANGED: ${image.changed}`);

        // core.info(image.source);

        // core.info(contents);

        // core.info('## Payload ##');
        // core.info(context.payload);

        // core.info('## Payload json ##');
        // core.info(JSON.stringify(context.payload, null, 2));

        // core.info('## Payload Commits json ##');
        // core.info(JSON.stringify(context.payload.commits, null, 2));

        if (!image.version) {
            core.warning(`Skipping ${imageName} because of missing version information`);
        } else {

            const imgDefShowCmd = [
                'sig', 'image-definition', 'show',
                '--only-show-errors',
                '-g', resourceGroup,
                '-r', galleryName,
                '-i', imageName
            ];

            core.info(`Checking if image definition exists for ${imageName}`);
            const imgDefShow = await exec.getExecOutput('az', imgDefShowCmd, { silent: true, ignoreReturnCode: true });

            if (imgDefShow.exitCode === 0) {
                core.info(`Found existing image ${imageName}`);
            } else if (imgDefShow.stderr.includes('Code: ResourceNotFound')) {

                core.info(`Image ${imageName} does not exist in gallery ${galleryName}`);

                const imgDefCreateCmd = [
                    'sig', 'image-definition', 'create',
                    '--only-show-errors',
                    '-g', resourceGroup,
                    '-r', galleryName,
                    '-i', imageName,
                    '-p', image.publisher,
                    '-f', image.offer,
                    '-s', image.sku,
                    '--os-type', image.os,
                    // '--os-state', 'Generalized', (default)
                    '--hyper-v-generation', 'V2',
                    '--features', 'SecurityType=TrustedLaunch'
                ];

                core.info(`Creating new image definition for ${imageName}`);

                const imgDefCreate = await exec.getExecOutput('az', imgDefCreateCmd, { silent: true, ignoreReturnCode: true });

                if (imgDefCreate.exitCode === 0) {
                    core.info(`Created image definition for ${imageName}`);
                } else {
                    core.setFailed(`Failed to create image definition for ${imageName} \n ${imgDefCreate.stderr}`);
                }

            } else {
                core.setFailed(`Failed to get image definition for ${imageName} \n ${imgDefShow.stderr}`);
            }

            // check it the image definition changed

            const imgVersionListCmd = [
                'sig', 'image-version', 'list',
                '--only-show-errors',
                '-g', resourceGroup,
                '-r', galleryName,
                '-i', imageName
            ];

            core.info(`Checking if image version exists for ${imageName}`);
            const imgVersionList = await exec.getExecOutput('az', imgVersionListCmd, { silent: true, ignoreReturnCode: true });

            core.info(`imgVersionList response: ${JSON.stringify(imgVersionList.stdout, null, 2)}`);

            const imgVersions = JSON.parse(imgVersionList.stdout);

            if (!imgVersions || imgVersions.length === 0 || !imgVersions.some(v => v.version === image.version)) {
                core.warning(`Image versions count ${imgVersions.length}`);

                matrix.include.push(image);
            }

            // for (const imgVersion of imgVersions) {

            //     if (true) {
            //     }
            // }


            // matrix.include.push(image);



            // if (imgVersionList.exitCode === 0 && imgVersionList.stdout) {

            //     const sig = JSON.parse(imgVersionList.stdout);
            //     core.info(sig);

            // } else {

            //     core.warning(`Could not find an existing image named ${imageName}`);

            // }
        }
    };

    core.info(JSON.stringify(matrix));

    core.setOutput('matrix', JSON.stringify(matrix));
};