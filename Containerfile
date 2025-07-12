ARG IMAGE_NAME="${IMAGE_NAME:-pulsar}"
ARG IMAGE_NAME="${IMAGE_FLAVOR:-main}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-reyemxela}"
ARG BASE_IMAGE="${BASE_IMAGE:-bazzite}"
ARG MAJOR_VERSION="${MAJOR_VERSION:-42}"

# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_scripts /build_scripts
COPY branding_files /branding_files

FROM ghcr.io/ublue-os/${BASE_IMAGE}:${MAJOR_VERSION}

ARG IMAGE_NAME="${IMAGE_NAME:-pulsar}"
ARG IMAGE_NAME="${IMAGE_FLAVOR:-main}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-reyemxela}"
ARG BASE_IMAGE="${BASE_IMAGE:-bazzite}"
ARG MAJOR_VERSION="${MAJOR_VERSION:-42}"

COPY system_files /

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build_scripts/_build.sh
