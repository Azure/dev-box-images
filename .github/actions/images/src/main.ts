import * as core from '@actions/core';
import { SummaryTableRow } from '@actions/core/lib/summary';

import { validateImageDefinitionAndVersion } from './azure';
import { getGallery } from './gallery';
import { getImages } from './images';
import { Image } from './types';

async function run(): Promise<void> {

    const include: Image[] = [];
    const skipped: Image[] = [];

    const gallery = await getGallery();

    const images = await getImages(gallery);

    for (const image of images) {
        const build = await validateImageDefinitionAndVersion(image);
        if (build)
            include.push(image);
        else
            skipped.push(image);
    }

    const headers = [
        { header: true, data: 'Name' },
        { header: true, data: 'Version' },
        { header: true, data: 'Publisher' },
        { header: true, data: 'Offer' },
        { header: true, data: 'SKU' },
        { header: true, data: 'OS' },
        { header: true, data: 'Resource Group' },
    ];

    if (include.length > 0) {

        const includeRows: SummaryTableRow[] = [headers];

        for (const i of include) {
            includeRows.push([
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
            .addTable(includeRows).write();

    } else {
        await core.summary.addHeading('No images were built', 4).write();
    }

    if (skipped.length > 0) {

        headers.pop();

        const skippedRows: SummaryTableRow[] = [headers];

        for (const i of skipped) {
            skippedRows.push([
                i.name,
                i.version,
                i.publisher,
                i.offer,
                i.sku,
                i.os,
            ]);
        }

        await core.summary
            .addHeading('Images skipped for update', 3)
            .addTable(skippedRows).write();

    } else {
        await core.summary.addHeading('No images were skipped', 4).write();
    }

    const matrix = {
        include: include
    };

    core.setOutput('matrix', JSON.stringify(matrix));
    core.setOutput('build', matrix.include.length > 0);
}

run();