export repo_organization := env("GITHUB_REPOSITORY_OWNER", "reyemxela")
export default_image_name := env("IMAGE_NAME", "pulsar")
export default_major_version := env("MAJOR_VERSION", "43")
export default_tag := env("DEFAULT_TAG", "stable")
base_images := '(
    [pulsar]="bazzite:stable-${version}"
    [pulsar-nvidia]="bazzite:stable-${version}"
    [pulsar-deck]="bazzite-deck:stable-${version}"
    [pulsar-cli]="base-main:${version}"
    [pulsar-cli-nvidia]="base-main:${version}"
)'

[private]
default:
    @just --list

# prints "base_image_name:tag" for the specified image/version
[group('Utility')]
get-base-image $image=default_image_name $version=default_major_version:
    #!/usr/bin/env bash
    set -euo pipefail

    declare -A base_images={{ base_images }}
    echo "${base_images[$image]}"

# prints flavor of the specified image: 'pulsar' -> 'main' | 'pulsar-cli' -> 'cli'
[group('Utility')]
get-image-flavor $image=default_image_name:
    #!/usr/bin/env bash
    set -euo pipefail
    shopt -s extglob

    if [[ $image == "pulsar" || $image == "pulsar-nvidia" ]]; then
        image_flavor=${image/pulsar/main}
    else
        image_flavor=${image/pulsar?(-)/}
    fi

    echo "$image_flavor"

# prints container labels
[group('Utility')]
get-labels $image=default_image_name:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "\
    org.opencontainers.image.created=$(date -u +%Y\-%m\-%d\T%H\:%M\:%S\Z)
    org.opencontainers.image.description=Customized Universal Blue images with some extras
    org.opencontainers.image.documentation=https://github.com/${repo_organization}/pulsar
    org.opencontainers.image.source=https://github.com/${repo_organization}/pulsar/blob/main/Containerfile
    org.opencontainers.image.title=${image}
    org.opencontainers.image.url=https://github.com/${repo_organization}/pulsar
    org.opencontainers.image.vendor=${repo_organization}
    io.artifacthub.package.readme-url=https://raw.githubusercontent.com/${repo_organization}/pulsar/refs/heads/main/README.md
    io.artifacthub.package.logo-url=https://raw.githubusercontent.com/${repo_organization}/pulsar/refs/heads/main/logo.svg
    io.artifacthub.package.maintainers=[{\"name\":\"reyemxela\",\"email\":\"alexwreyem@gmail.com\"}]
    io.artifacthub.package.keywords=bootc,fedora,pulsar,ublue,universal-blue
    io.artifacthub.package.license=Apache-2.0
    containers.bootc=1
    "

# prints tags for the container image
[group('Utility')]
get-tags $tag=default_tag $version=default_major_version:
    #!/usr/bin/env bash
    set -eou pipefail

    tags="${tag} ${tag}-${version}"

    # "stable" also gets "latest" and "<version>"
    if [[ $tag == "stable" ]]; then
        tags="${tags} latest ${version}"
    fi
    echo "${tags}"

# builds specified image as "image_name:tag"
[group('Build')]
build $image=default_image_name $version=default_major_version $tag=default_tag:
    #!/usr/bin/env bash

    base_image="$(just get-base-image ${image})"
    image_flavor="$(just get-image-flavor ${image})"

    BUILD_ARGS=()
    BUILD_ARGS+=("--build-arg" "IMAGE_NAME=${image}")
    BUILD_ARGS+=("--build-arg" "IMAGE_FLAVOR=${image_flavor}")
    BUILD_ARGS+=("--build-arg" "IMAGE_VENDOR=${repo_organization}")
    BUILD_ARGS+=("--build-arg" "BASE_IMAGE=${base_image}")
    BUILD_ARGS+=("--build-arg" "MAJOR_VERSION=${version}")

    podman build \
        "${BUILD_ARGS[@]}" \
        --pull=newer \
        --tag "${image}:${tag}" \
        .

[group('Build')]
rechunk $image=default_image_name $version=default_major_version $tag=default_tag $fresh='false':
    #!/usr/bin/env bash

    echo "::group:: Rechunk Build Prep"
    set -eou pipefail

    if [[ "${UID}" -eq "0" ]]; then
        echo "Must not be run as root!"
        exit 1
    fi

    REF=localhost/${image}:${tag}
    RECHUNK=ghcr.io/hhd-dev/rechunk:latest

    CREF=$(sudo podman create ${REF} bash)
    MOUNT=$(sudo podman mount "$CREF")
    OUT_NAME="${image}_${tag}"
    VERSION="${version}.$(date '+%Y%m%d')"

    sudo podman pull ${RECHUNK}

    echo "::endgroup::"

    echo "::group:: Rechunk Prune"
    sudo podman run --rm \
        --security-opt label=disable \
        -v "$MOUNT":/var/tree \
        -e TREE=/var/tree \
        -u 0:0 \
        ${RECHUNK} \
        /sources/rechunk/1_prune.sh
    echo "::endgroup::"

    echo "::group:: Create Tree"
    sudo podman run --rm \
        --security-opt label=disable \
        -v "$MOUNT":/var/tree \
        -e TREE=/var/tree \
        -v "cache_ostree:/var/ostree" \
        -e REPO=/var/ostree/repo \
        -e RESET_TIMESTAMP=1 \
        -u 0:0 \
        ${RECHUNK} \
        /sources/rechunk/2_create.sh
    sudo podman unmount "$CREF"
    sudo podman rm "$CREF"
    sudo podman rmi ${REF}
    echo "::endgroup::"

    echo "::group:: Rechunk"
    if [[ $fresh == "true" ]]; then
        PREV_REF=""
    else
        PREV_REF="ghcr.io/${repo_organization}/${image}:${tag}"
    fi
    sudo podman run --rm \
        --security-opt label=disable \
        -v "$PWD:/workspace" \
        -v "$PWD:/var/git" \
        -v cache_ostree:/var/ostree \
        -e REPO=/var/ostree/repo \
        -e PREV_REF=$PREV_REF \
        -e OUT_NAME="$OUT_NAME" \
        -e LABELS="'$(just get-labels $image)'" \
        -e VERSION="$VERSION" \
        -e VERSION_FN=/workspace/version.txt \
        -e OUT_REF="oci:$OUT_NAME" \
        -e GIT_DIR="/var/git" \
        -u 0:0 \
        ${RECHUNK} \
        /sources/rechunk/3_chunk.sh
    echo "::endgroup::"

    echo "::group:: Cleanup"
    sudo find ${OUT_NAME} -type d -exec chmod 0755 {} \; || true
    sudo find ${OUT_NAME}* -type f -exec chmod 0644 {} \; || true
    sudo chown $(id -u):$(id -g) -R "${PWD}"
    sudo podman volume rm cache_ostree
    echo "::endgroup::"

[group('Build')]
load_image $image=default_image_name $version=default_major_version $tag=default_tag:
    #!/usr/bin/env bash
    set -eou pipefail

    OUT_NAME="${image}_${tag}"

    IMAGE_ID=$(podman pull oci:$OUT_NAME)
    podman tag ${IMAGE_ID} localhost/${image}:${tag}
    for t in $(just get-tags $tag $version); do
        podman tag ${IMAGE_ID} localhost/${image}:${t}
    done
    podman images
    rm -rf $OUT_NAME

# Check Just Syntax
[group('Just')]
check:
    #!/usr/bin/bash
    find . -type f -name "*.just" | while read -r file; do
    	echo "Checking syntax: $file"
    	just --unstable --fmt --check -f $file
    done
    echo "Checking syntax: Justfile"
    just --unstable --fmt --check -f Justfile

# Fix Just Syntax
[group('Just')]
fix:
    #!/usr/bin/bash
    find . -type f -name "*.just" | while read -r file; do
    	echo "Checking syntax: $file"
    	just --unstable --fmt -f $file
    done
    echo "Checking syntax: Justfile"
    just --unstable --fmt -f Justfile || { exit 1; }
