# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

FROM mcr.microsoft.com/azure-cli:latest
WORKDIR /

ARG IMAGE_VERSION

# Metadata as defined at http://label-schema.org
ARG BUILD_DATE

ENV ACI_IMAGE_BUILDER=1
ENV ACI_IMAGE_BUILDER_VERSION=$IMAGE_VERSION

LABEL maintainer="Microsoft" \
    org.opencontainers.image.created=$BUILD_DATE \
    org.opencontainers.image.url="https://github.com/azure/dev-box-images" \
    org.opencontainers.image.source="https://github.com/azure/dev-box-images" \
    org.opencontainers.image.version=$IMAGE_VERSION \
    org.opencontainers.image.vendor="Microsoft" \
    org.opencontainers.image.title="Dev Box Image Builder" \
    org.opencontainers.image.description="The Dev Box Image Builder is used to build images using packer." \
    org.opencontainers.image.documentation="https://github.com/azure/dev-box-images/tree/main/builder" \
    org.opencontainers.image.licenses="MIT" \
    org.label-schema.schema-version="1.0" \
    org.label-schema.vendor="Microsoft" \
    org.label-schema.name="Dev Box Image Builder" \
    org.label-schema.version=$IMAGE_VERSION \
    org.label-schema.license="MIT" \
    org.label-schema.description="The Dev Box Image Builder is used to build images using packer." \
    org.label-schema.url="https://github.com/azure/dev-box-images" \
    org.label-schema.usage="https://github.com/azure/dev-box-images/tree/main/builder" \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.vcs-url="https://github.com/azure/dev-box-images.git" \
    org.label-schema.docker.cmd="docker run ghcr.io/azure/dev-box-images/builder:$IMAGE_VERSION"

# install packer
RUN apk add --no-cache packer --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community

COPY . /builder.d

# Terminate container on stop
STOPSIGNAL SIGTERM

CMD [ "" ]
ENTRYPOINT [ "python", "/builder.d/builder.py" ]