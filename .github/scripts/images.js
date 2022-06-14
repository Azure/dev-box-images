const fs = require('fs/promises');
const yaml = require('js-yaml');


module.exports = async ({ github, context, core, glob, exec, }) => {

    let matrix = {
        include: []
    };

    const patterns = ['**/image.yml', '**/image.yaml']
    const globber = await glob.create(patterns.join('\n'));
    const files = await globber.glob();

    for (const file of files) {
        core.info(`Found image configuration file at ${file}`);

        // Get image name from folder
        const imageName = file.split('/').slice(-2)[0];

        const contents = await fs.readFile(file, 'utf8');
        const image = yaml.load(contents);

        image.source = file.split('/image.y')[0];
        core.info(image.source);

        core.info(contents);

        core.info('## Payload ##');
        core.info(context.payload);

        core.info('## Payload json ##');
        core.info(JSON.stringify(context.payload, null, 2));

        core.info('## Payload Commits json ##');
        core.info(JSON.stringify(context.payload.commits, null, 2));

        if (!image.version) {

            core.warning(`Skipping ${imageName} because of missing version information`);

        } else {


            const imgDefShowCmd = [
                'sig', 'image-definition', 'show',
                '--only-show-errors',
                '-g', '${{ env.resourceGroup }}',
                '-r', '${{ env.galleryName }}',
                '-i', imageName
            ];

            const imgDefCreateCmd = [
                'sig', 'image-definition', 'create',
                '--only-show-errors',
                '-g', '${{ env.resourceGroup }}',
                '-r', '${{ env.galleryName }}',
                '-i', imageName,
                '-p', image.publisher,
                '-f', image.offer,
                '-s', image.sku,
                '--os-type', image.os,
                // '--os-state', 'Generalized', (default)
                '--hyper-v-generation', 'V2',
                '--features', 'SecurityType=TrustedLaunch'
            ];


            const imgVersionListCmd = [
                'sig', 'image-version', 'list',
                '--only-show-errors',
                '-g', '${{ env.resourceGroup }}',
                '-r', '${{ env.galleryName }}',
                '-i', imageName,
                '--query', `[?name == '${image.version}'] | [0]`
            ];

            const sigList = await exec.getExecOutput('az', imgVersionListCmd, { ignoreReturnCode: true });

            matrix.include.push(image);

            if (sigList.exitCode === 0 && sigList.stdout) {

                const sig = JSON.parse(sigList.stdout);
                core.info(sig);

            } else {

                core.warning(`Could not find an existing image named ${imageName}`);

            }
        }
    };

    core.info(JSON.stringify(matrix));

    core.setOutput('matrix', JSON.stringify(matrix));
};