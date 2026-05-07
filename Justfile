export repo_organization := env("GITHUB_REPOSITORY_OWNER", "reyemxela")
export default_image_name := env("IMAGE_NAME", "pulsar")
export default_major_version := env("MAJOR_VERSION", "44")
export default_tag := env("DEFAULT_TAG", "stable")
base_images := '(
    [pulsar]="bazzite:stable-${version}"
    [pulsar-nvidia]="bazzite:stable-${version}"
    [pulsar-deck]="bazzite-deck:stable-${version}"
    [pulsar-cli]="base-main:${version}"
    [pulsar-cli-nvidia]="base-main:${version}"
)'
just := just_executable()

[private]
default:
    @{{ just }} --list

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

[group('Utility')]
secureboot $image=default_image_name $tag=default_tag:
    #!/usr/bin/bash
    set -eoux pipefail

    # Get the vmlinuz to check
    kernel_release=$(podman inspect "${image}":"${tag}" | jq -r '.[].Config.Labels["ostree.linux"]')
    TMP=$(podman create "${image}":"${tag}" bash)
    podman cp "$TMP":/usr/lib/modules/"${kernel_release}"/vmlinuz /tmp/vmlinuz
    podman rm "$TMP"

    # Get the Public Certificates
    curl --retry 3 -Lo /tmp/kernel-sign.der https://github.com/ublue-os/akmods/raw/main/certs/public_key.der
    curl --retry 3 -Lo /tmp/akmods.der https://github.com/ublue-os/akmods/raw/main/certs/public_key_2.der
    openssl x509 -in /tmp/kernel-sign.der -out /tmp/kernel-sign.crt
    openssl x509 -in /tmp/akmods.der -out /tmp/akmods.crt

    # Make sure we have sbverify
    CMD="$(command -v sbverify || true)"
    if [[ -z "${CMD:-}" ]]; then
        temp_name="sbverify-${RANDOM}"
        podman run -dt \
            --entrypoint /bin/sh \
            --volume /tmp/vmlinuz:/tmp/vmlinuz:z \
            --volume /tmp/kernel-sign.crt:/tmp/kernel-sign.crt:z \
            --volume /tmp/akmods.crt:/tmp/akmods.crt:z \
            --name ${temp_name} \
            alpine:edge
        podman exec ${temp_name} apk add sbsigntool
        CMD="podman exec ${temp_name} /usr/bin/sbverify"
    fi

    # Confirm that Signatures Are Good
    $CMD --list /tmp/vmlinuz
    returncode=0
    if ! $CMD --cert /tmp/kernel-sign.crt /tmp/vmlinuz || ! $CMD --cert /tmp/akmods.crt /tmp/vmlinuz; then
        echo "Secureboot Signature Failed...."
        returncode=1
    fi
    if [[ -n "${temp_name:-}" ]]; then
        podman rm -f "${temp_name}"
    fi
    exit "$returncode"

# builds specified image as "image_name:tag"
[group('Build')]
build $image=default_image_name $version=default_major_version $tag=default_tag:
    #!/usr/bin/env bash

    set -eoux pipefail

    base_image="$({{ just }} get-base-image ${image} ${version})"
    image_flavor="$({{ just }} get-image-flavor ${image})"

    ver="${version}.$(date '+%Y%m%d')"
    prev_ver="$(skopeo inspect docker://ghcr.io/${repo_organization}/${image}:${tag} |jq '.Labels["org.opencontainers.image.version"]')"
    if [[ "$prev_ver" =~ "$ver" ]]; then
        shopt -s extglob
        point=${prev_ver/#${ver}?(.)/}
        ((++point))
        ver="${ver}.${point}"
    fi

    BUILD_ARGS=()
    BUILD_ARGS+=("--build-arg" "IMAGE_NAME=${image}")
    BUILD_ARGS+=("--build-arg" "IMAGE_FLAVOR=${image_flavor}")
    BUILD_ARGS+=("--build-arg" "IMAGE_VENDOR=${repo_organization}")
    BUILD_ARGS+=("--build-arg" "BASE_IMAGE=${base_image}")
    BUILD_ARGS+=("--build-arg" "MAJOR_VERSION=${version}")

    LABELS=()
    LABELS+=("--label" "org.opencontainers.image.created=$(date -u +%Y\-%m\-%d\T%H\:%M\:%S\Z)")
    LABELS+=("--label" "org.opencontainers.image.version=${ver}")
    LABELS+=("--label" "org.opencontainers.image.description=Customized Universal Blue images with some extras")
    LABELS+=("--label" "org.opencontainers.image.documentation=https://github.com/${repo_organization}/pulsar")
    LABELS+=("--label" "org.opencontainers.image.source=https://github.com/${repo_organization}/pulsar/blob/main/Containerfile")
    LABELS+=("--label" "org.opencontainers.image.title=${image}")
    LABELS+=("--label" "org.opencontainers.image.url=https://github.com/${repo_organization}/pulsar")
    LABELS+=("--label" "org.opencontainers.image.vendor=${repo_organization}")
    LABELS+=("--label" "io.artifacthub.package.readme-url=https://raw.githubusercontent.com/${repo_organization}/pulsar/refs/heads/main/README.md")
    LABELS+=("--label" "io.artifacthub.package.logo-url=https://raw.githubusercontent.com/${repo_organization}/pulsar/refs/heads/main/logo.svg")
    LABELS+=("--label" "io.artifacthub.package.maintainers=[{\"name\":\"reyemxela\",\"email\":\"alexwreyem@gmail.com\"}]")
    LABELS+=("--label" "io.artifacthub.package.keywords=bootc,fedora,pulsar,ublue,universal-blue")
    LABELS+=("--label" "io.artifacthub.package.license=Apache-2.0")
    LABELS+=("--label" "containers.bootc=1")

    podman build \
        "${BUILD_ARGS[@]}" \
        "${LABELS[@]}" \
        --pull=newer \
        --tag "${image}:${tag}" \
        .

[group('Build')]
rechunk $image=default_image_name $version=default_major_version $tag=default_tag $fresh='false':
    #!/usr/bin/env bash

    set -eou pipefail

    if [[ "${UID}" -ne "0" ]]; then
        echo "Must be run as root!"
        exit 1
    fi

    base_image="ghcr.io/ublue-os/$({{ just }} get-base-image ${image} ${version})"
    image_name="localhost/${image}:${tag}"

    # TODO: add -previous-build when it's available in rpm-ostree
    podman run --rm \
        --pull=newer \
        --privileged \
        -v "/var/lib/containers:/var/lib/containers" \
        --entrypoint /usr/bin/rpm-ostree \
        "${base_image}" \
        compose build-chunked-oci \
        --max-layers 127 \
        --format-version=2 \
        --bootc \
        --from "${image_name}" \
        --output "containers-storage:${image_name}"

[group('Build')]
tag-image $image=default_image_name $version=default_major_version $tag=default_tag:
    #!/usr/bin/env bash
    set -eou pipefail

    for t in $({{ just }} get-tags $tag $version); do
        podman tag localhost/${image}:${tag} localhost/${image}:${t}
    done
    podman images

[group('Build')]
build-iso $image=default_image_name $version=default_major_version $tag=default_tag $local="true":
    #!/usr/bin/env bash
    set -eou pipefail

    if [[ "${UID}" -ne "0" ]]; then
        echo "Must be run as root!"
        exit 1
    fi

    mkdir -p output

    isoname="${image}-${version}-${tag}.iso"

    rm -f "output/${isoname}"*

    if [[ $local == "true" ]]; then
        id="$(podman images --filter reference="${image}:${tag}" --format "{{{{.ID}}")"
        if [[ $id != "" ]]; then
            src="containers-storage:${id}"
        else
            echo "${image}:${tag} not found locally!"
            exit 1
        fi
    else
        src="docker://ghcr.io/${repo_organization}/${image}:${tag}"
    fi

    podman run --rm --privileged \
        --pull=newer \
        --volume ./output:/build-container-installer/build \
        --volume /var/lib/containers/storage:/var/lib/containers/storage \
        ghcr.io/jasonn3/build-container-installer:latest \
        VERSION=$version \
        IMAGE_NAME=$image \
        IMAGE_TAG=$tag \
        IMAGE_REPO="ghcr.io/${repo_organization}" \
        IMAGE_SRC=$src \
        ISO_NAME="build/${isoname}"
        VARIANT=kinoite

    if [[ -n "${SUDO_USER:-}" ]]; then
        chown -R "${SUDO_UID}":"${SUDO_GID}" output
    fi

# Check Just Syntax
[group('Just')]
check:
    #!/usr/bin/bash
    find . -type f -name "*.just" | while read -r file; do
    	echo "Checking syntax: $file"
    	{{ just }} --unstable --fmt --check -f $file
    done
    echo "Checking syntax: Justfile"
    {{ just }} --unstable --fmt --check -f Justfile

# Fix Just Syntax
[group('Just')]
fix:
    #!/usr/bin/bash
    find . -type f -name "*.just" | while read -r file; do
    	echo "Checking syntax: $file"
    	{{ just }} --unstable --fmt -f $file
    done
    echo "Checking syntax: Justfile"
    {{ just }} --unstable --fmt -f Justfile || { exit 1; }
