export interface Repo {
    url: string;
    org: string;
    project?: string;
    repo: string;
    cloneUrl: string;
    cloneUrlTemplate: string;
    secret: string;
}

export interface Image {
    name: string;
    description: string;

    publisher: string;
    offer: string;
    sku: string;
    os: string;

    version: string;

    repos: Repo[];

    galleryResourceGroup: string;
    galleryName: string;

    // gallery: Gallery;

    source: string;
    path: string;

    location?: string;
    locations: string;

    changed: boolean;

    useBuildGroup: boolean;
    tempResourceGroup?: string;
    buildResourceGroup?: string;
    resolvedResourceGroup: string;
}

export interface Gallery {
    name: string;
    resourceGroup: string;
}
