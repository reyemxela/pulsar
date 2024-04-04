ARG IMAGE_NAME="${IMAGE_NAME:-kinoite}"
ARG IMAGE_SUFFIX="${IMAGE_SUFFIX:-main}"
ARG FULL_IMAGE_NAME="${IMAGE_NAME}${IMAGE_SUFFIX:+-$IMAGE_SUFFIX}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-39}"

FROM ghcr.io/ublue-os/${FULL_IMAGE_NAME}:${FEDORA_MAJOR_VERSION}

ARG IMAGE_NAME="${IMAGE_NAME:-kinoite}"
ARG IMAGE_SUFFIX="${IMAGE_SUFFIX:-main}"
ARG FULL_IMAGE_NAME="${IMAGE_NAME}${IMAGE_SUFFIX:+-$IMAGE_SUFFIX}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-39}"

COPY usr /usr

RUN mkdir -p /usr/share/ublue-os && \
    echo "$FULL_IMAGE_NAME" >/usr/share/ublue-os/image-name

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
