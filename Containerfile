ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-main}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-reyemxela}"
ARG BASE_IMAGE="${BASE_IMAGE:-bazzite}"
ARG MAJOR_VERSION="${MAJOR_VERSION:-41}"

FROM ghcr.io/ublue-os/${BASE_IMAGE}:${MAJOR_VERSION}

ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-main}"
ARG IMAGE_VENDOR="${IMAGE_VENDOR:-reyemxela}"
ARG BASE_IMAGE="${BASE_IMAGE:-bazzite}"
ARG MAJOR_VERSION="${MAJOR_VERSION:-41}"

COPY system_files /
COPY branding_files /tmp/branding_files
COPY build_scripts /tmp/build_scripts

RUN /tmp/build_scripts/_build.sh
