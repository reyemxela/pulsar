ARG IMAGE_NAME="${IMAGE_NAME:-kinoite}"
ARG IMAGE_SUFFIX="${IMAGE_SUFFIX:-main}"
ARG FULL_IMAGE_NAME="${IMAGE_NAME}${IMAGE_SUFFIX:+-$IMAGE_SUFFIX}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-41}"
ARG KERNEL_FLAVOR="${KERNEL_FLAVOR}"
ARG KERNEL_VERSION="${KERNEL_VERSION}"

FROM ghcr.io/ublue-os/${FULL_IMAGE_NAME}:${FEDORA_MAJOR_VERSION} AS default

ARG IMAGE_NAME="${IMAGE_NAME:-kinoite}"
ARG IMAGE_SUFFIX="${IMAGE_SUFFIX:-main}"
ARG FULL_IMAGE_NAME="${IMAGE_NAME}${IMAGE_SUFFIX:+-$IMAGE_SUFFIX}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-41}"
ARG KERNEL_FLAVOR="${KERNEL_FLAVOR}"
ARG KERNEL_VERSION="${KERNEL_VERSION}"

# reinstall ublue-os-update-services for images that use ublue-update instead
COPY --from=ghcr.io/ublue-os/config:latest /files/ublue-os-update-services /

COPY system_files /

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


FROM default AS customkernel

ARG IMAGE_NAME="${IMAGE_NAME:-kinoite}"
ARG IMAGE_SUFFIX="${IMAGE_SUFFIX:-main}"
ARG FULL_IMAGE_NAME="${IMAGE_NAME}${IMAGE_SUFFIX:+-$IMAGE_SUFFIX}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-41}"
ARG KERNEL_FLAVOR="${KERNEL_FLAVOR}"
ARG KERNEL_VERSION="${KERNEL_VERSION}"

COPY --from=ghcr.io/ublue-os/${KERNEL_FLAVOR}-kernel:${FEDORA_MAJOR_VERSION}-${KERNEL_VERSION} /tmp/rpms /tmp/kernel-rpms

RUN rpm-ostree cliwrap install-to-root / && \
    echo "Will install ${KERNEL_FLAVOR} kernel" && \
    rpm-ostree override replace \
    --experimental \
        /tmp/kernel-rpms/kernel-[0-9]*.rpm \
        /tmp/kernel-rpms/kernel-core-*.rpm \
        /tmp/kernel-rpms/kernel-modules-*.rpm \
        /tmp/kernel-rpms/kernel-uki-virt-*.rpm && \
    rm -rf /tmp/* /var/* && \
    ostree container commit && \
    mkdir -p /tmp /var/tmp && \
    chmod 1777 /tmp /var/tmp