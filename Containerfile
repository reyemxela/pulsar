ARG IMAGE_NAME="${IMAGE_NAME:-kinoite}"
ARG IMAGE_SUFFIX="${IMAGE_SUFFIX:-main}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-39}"

FROM ghcr.io/ublue-os/${IMAGE_NAME}-${IMAGE_SUFFIX}:${FEDORA_MAJOR_VERSION}

ARG IMAGE_NAME="${IMAGE_NAME:-kinoite}"
ARG IMAGE_SUFFIX="${IMAGE_SUFFIX:-main}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-39}"

COPY usr /usr

COPY packages.sh \
     packages.json \
     flatpaks.sh \
     flatpaks.json \
     extras.sh \
     post-install.sh \
     /tmp/

RUN /tmp/packages.sh && \
    /tmp/flatpaks.sh && \
    /tmp/extras.sh && \
    /tmp/post-install.sh

RUN rm -rf /tmp/* /var/* && \
    ostree container commit && \
    mkdir -p /tmp /var/tmp && \
    chmod 1777 /tmp /var/tmp
