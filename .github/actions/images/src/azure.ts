import * as core from '@actions/core';
import * as exec from '@actions/exec';
import { Image } from './types';

const RESOURCE_NOT_FOUND = 'Code: ResourceNotFound';
const SECRET_NOT_FOUND = '(SecretNotFound)';
const SECRET_FORBIDDEN = 'Caller is not authorized to perform action on resource.';

export async function getKeyVaultSecret(id: string): Promise<string | undefined> {

    try {

        const secretShowCmd = [
            'keyvault',
            'secret',
            'show',
            '--id', id,
        ];

        core.info(`Getting secret from Key Vault: ${id}`);
        const secretShow = await exec.getExecOutput('az', secretShowCmd, { silent: true, ignoreReturnCode: true });

        if (secretShow.exitCode === 0) {

            const secret = JSON.parse(secretShow.stdout);
            core.setSecret(secret.value);
            return secret.value;

        } else if (secretShow.stderr.includes(SECRET_NOT_FOUND))
            core.setFailed(`Key Vault secret ${id} not found`);
        else if (secretShow.stderr.includes(SECRET_FORBIDDEN))
            core.setFailed(`Service Principal used to login to Azure does not have permission to read Key Vault secret ${id}`);
        else
            core.setFailed(`Error getting secret from Key Vault: ${secretShow.stderr}`);

    } catch (error) {
        if (error instanceof Error) core.setFailed(error.message);
    }

    return undefined;
};

export async function validateImageDefinitionAndVersion(image: Image): Promise<boolean> {

    core.startGroup(`Validating image definition and version for ${image.name}`);

    try {
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
            image.location = image.useBuildGroup ? '' : img.location;

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
                if (imgVersionShow.stderr.includes(RESOURCE_NOT_FOUND)) {

                    // image version does not exist, add it to the list of images to create
                    core.info(`Image version ${image.version} does not exist for ${image.name}. Creating`);
                    // include.push(image);

                    core.endGroup();
                    return true;

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

        } else if (imgDefShow.stderr.includes(RESOURCE_NOT_FOUND)) {

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
                image.location = image.useBuildGroup ? '' : img.location;

                core.endGroup();
                return true;

            } else {
                core.setFailed(`Failed to create image definition for ${image.name} \n ${imgDefCreate.stderr}`);
            }

        } else {
            core.setFailed(`Failed to get image definition for ${image.name} \n ${imgDefShow.stderr}`);
        }

    } catch (error) {
        if (error instanceof Error) core.setFailed(error.message);
    }

    core.endGroup();
    return false;
};