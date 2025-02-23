export repo_organization := env("GITHUB_REPOSITORY_OWNER", "reyemxela")
export image_flavor := env("IMAGE_FLAVOR", "main")
export major_version := env("MAJOR_VERSION", "41")
export default_tag := env("DEFAULT_TAG", "latest")
export bib_image := env("BIB_IMAGE", "quay.io/centos-bootc/bootc-image-builder:latest")
export SUDO_DISPLAY := if `if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then echo true; fi` == "true" { "true" } else { "false" }
export SUDOIF := if `id -u` == "0" { "" } else { if SUDO_DISPLAY == "true" { "sudo --askpass" } else { "sudo" } }
export PODMAN := if path_exists("/usr/bin/podman") == "true" { env("PODMAN", "/usr/bin/podman") } else { if path_exists("/usr/bin/docker") == "true" { env("PODMAN", "docker") } else { env("PODMAN", "exit 1 ; ") } }

alias build-vm := build-qcow2
alias rebuild-vm := rebuild-qcow2
alias run-vm := run-vm-qcow2

base_images := '(
    [main]="bazzite"
    [main-nvidia]="bazzite-nvidia"
    [deck]="bazzite-deck"
    [cli]="base-main"
    [cli-nvidia]="base-nvidia"
)'

[private]
default:
    @just --list

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

# Clean Repo
[group('Utility')]
clean:
    #!/usr/bin/bash
    set -eoux pipefail
    touch _build
    find *_build* -exec rm -rf {} \;
    rm -f previous.manifest.json
    rm -f changelog.md
    rm -f output.env

# Sudo Clean Repo
[group('Utility')]
[private]
sudo-clean:
    ${SUDOIF} just clean

[group('Utility')]
[private]
get-image-name $flavor=image_flavor:
    #!/usr/bin/env bash
    IMAGE_NAME="pulsar-${flavor}"
    echo "${IMAGE_NAME/%-main/}"

[group('Utility')]
[private]
get-base-image $flavor=image_flavor:
    #!/usr/bin/env bash
    set -euo pipefail

    declare -A base_images={{ base_images }}
    echo "${base_images[$flavor]}"

[group('Utility')]
[private]
get-labels $flavor=image_flavor $repo=repo_organization $version=major_version:
    #!/usr/bin/env bash
    set -euo pipefail

    target_image="$(just get-image-name ${flavor})"

    echo "\
    org.opencontainers.image.created=$(date -u +%Y\-%m\-%d\T%H\:%M\:%S\Z)
    org.opencontainers.image.description=Customized Universal Blue images with some extras
    org.opencontainers.image.documentation=https://github.com/${repo}/pulsar
    org.opencontainers.image.source=https://github.com/${repo}/pulsar/blob/main/Containerfile
    org.opencontainers.image.title=${target_image}
    org.opencontainers.image.url=https://github.com/${repo}/pulsar
    org.opencontainers.image.vendor=${repo}
    io.artifacthub.package.readme-url=https://raw.githubusercontent.com/${repo}/pulsar/refs/heads/main/README.md
    io.artifacthub.package.logo-url=https://raw.githubusercontent.com/${repo}/pulsar/refs/heads/main/logo.svg
    io.artifacthub.package.maintainers=[{\"name\":\"reyemxela\",\"email\":\"alexwreyem@gmail.com\"}]
    io.artifacthub.package.keywords=bootc,fedora,pulsar,ublue,universal-blue
    io.artifacthub.package.license=Apache-2.0
    containers.bootc=1
    "

build $flavor=image_flavor $tag=default_tag $repo=repo_organization $version=major_version:
    #!/usr/bin/env bash
    set -euo pipefail

    base_image="$(just get-base-image ${flavor})"
    target_image="$(just get-image-name ${flavor})"

    BUILD_ARGS=()
    BUILD_ARGS+=("--build-arg" "IMAGE_FLAVOR=${flavor}")
    BUILD_ARGS+=("--build-arg" "IMAGE_VENDOR=${repo}")
    BUILD_ARGS+=("--build-arg" "BASE_IMAGE=${base_image}")
    BUILD_ARGS+=("--build-arg" "MAJOR_VERSION=${version}")

    ${PODMAN} build \
        "${BUILD_ARGS[@]}" \
        --pull=newer \
        --tag "${target_image}:${tag}" \
        .

rechunk $flavor=image_flavor $fresh='false' $tag=default_tag $repo=repo_organization $version=major_version:
    #!/usr/bin/env bash

    echo "::group:: Rechunk Build Prep"
    set -eou pipefail

    if [[ ! ${PODMAN} =~ podman ]]; then
        echo "Rechunk only supported with podman. Exiting..."
        exit 0
    fi

    target_image="$(just get-image-name ${flavor})"

    REF=localhost/${target_image}:${tag}
    RECHUNK=ghcr.io/hhd-dev/rechunk:latest

    ID=$(${PODMAN} images --filter reference=${REF} --format "'{{ '{{.ID}}' }}'")

    if [[ -z "$ID" ]]; then
        just build $flavor $tag $repo $version
    fi

    if [[ "${UID}" -gt "0" ]]; then
        COPYTMP="$(mktemp -p "${PWD}" -d -t podman_scp.XXXXXXXXXX)"
        ${SUDOIF} TMPDIR="${COPYTMP}" ${PODMAN} image scp "${UID}"@localhost::${REF} root@localhost::${REF}
        rm -rf "${COPYTMP}"
    fi

    CREF=$(${SUDOIF} ${PODMAN} create ${REF} bash)
    MOUNT=$(${SUDOIF} ${PODMAN} mount "$CREF")
    OUT_NAME="${target_image}_${tag}"
    # VERSION="$(${SUDOIF} ${PODMAN} inspect "$CREF" | jq -r '.[]["Config"]["Labels"]["org.opencontainers.image.version"]')"
    VERSION="${version}.$(date '+%Y%m%d')"

    echo "::endgroup::"

    echo "::group:: Rechunk Prune"
    ${SUDOIF} ${PODMAN} run --rm \
        --security-opt label=disable \
        --volume "$MOUNT":/var/tree \
        --env TREE=/var/tree \
        --user 0:0 \
        ${RECHUNK} \
        /sources/rechunk/1_prune.sh
    echo "::endgroup::"

    echo "::group:: Create Tree"
    ${SUDOIF} ${PODMAN} run --rm \
        --security-opt label=disable \
        --volume "$MOUNT":/var/tree \
        --volume "cache_ostree:/var/ostree" \
        --env TREE=/var/tree \
        --env REPO=/var/ostree/repo \
        --env RESET_TIMESTAMP=1 \
        --user 0:0 \
        ${RECHUNK} \
        /sources/rechunk/2_create.sh
    ${SUDOIF} ${PODMAN} unmount "$CREF"
    ${SUDOIF} ${PODMAN} rm "$CREF"
    if [[ "${UID}" -gt "0" ]]; then
        ${SUDOIF} ${PODMAN} rmi ${REF}
    fi
    ${PODMAN} rmi ${REF}
    echo "::endgroup::"

    echo "::group:: Rechunk"
    if [[ $fresh == "true" ]]; then
        PREV_REF=""
    else
        PREV_REF="ghcr.io/${repo_organization}/${target_image}:${tag}"
    fi
    ${SUDOIF} ${PODMAN} run --rm \
        --pull=newer \
        --security-opt label=disable \
        --volume "$PWD:/workspace" \
        --volume "$PWD:/var/git" \
        --volume cache_ostree:/var/ostree \
        --env REPO=/var/ostree/repo \
        --env PREV_REF=$PREV_REF \
        --env LABELS="$(just get-labels $flavor $repo $version)" \
        --env OUT_NAME="$OUT_NAME" \
        --env VERSION="$VERSION" \
        --env VERSION_FN=/workspace/version.txt \
        --env OUT_REF="oci:$OUT_NAME" \
        --env GIT_DIR="/var/git" \
        --user 0:0 \
        ${RECHUNK} \
        /sources/rechunk/3_chunk.sh
    echo "::endgroup::"

    echo "::group:: Cleanup"
    ${SUDOIF} find ${target_image}_${tag} -type d -exec chmod 0755 {} \; || true
    ${SUDOIF} find ${target_image}_${tag}* -type f -exec chmod 0644 {} \; || true
    if [[ "${UID}" -gt "0" ]]; then
        ${SUDOIF} chown -R "${UID}":"${GROUPS[0]}" "${PWD}"
        just load-image ${flavor} ${tag}
    elif [[ "${UID}" == "0" && -n "${SUDO_USER:-}" ]]; then
        ${SUDOIF} chown -R "${SUDO_UID}":"${SUDO_GID}" "/run/user/${SUDO_UID}/just"
        ${SUDOIF} chown -R "${SUDO_UID}":"${SUDO_GID}" "${PWD}"
    fi

    ${SUDOIF} ${PODMAN} volume rm cache_ostree
    echo "::endgroup::"

[private]
load-image $flavor=image_flavor $tag=default_tag $version=major_version:
    #!/usr/bin/env bash
    set -eou pipefail
    
    target_image="$(just get-image-name ${flavor})"
    OUT_NAME="${target_image}_${tag}"

    IMAGE=$(${PODMAN} pull oci:${PWD}/$OUT_NAME)
    ${PODMAN} tag ${IMAGE} localhost/${target_image}:${tag}
    for t in $(just get-tags $flavor $tag $version); do
        ${PODMAN} tag ${IMAGE} localhost/${target_image}:${t}
    done
    ${PODMAN} images
    rm -rf $OUT_NAME

get-tags $flavor=image_flavor $tag=default_tag $version=major_version:
    #!/usr/bin/env bash
    set -eou pipefail
    
    target_image="$(just get-image-name ${flavor})"

    echo "${tag} ${version}"

[private]
rootful-load-image $flavor=image_flavor $repo='localhost' $tag=default_tag:
    #!/usr/bin/bash
    set -eoux pipefail

    if [[ -n "${SUDO_USER:-}" || "${UID}" -eq "0" ]]; then
        echo "Already root or running under sudo, no need to load image from user ${PODMAN}."
        exit 0
    fi

    target_image="${repo}/$(just get-image-name ${flavor})"

    set +e
    resolved_tag=$(${PODMAN} inspect -t image "${target_image}:${tag}" | jq -r '.[].RepoTags.[0]')
    return_code=$?
    set -e

    if [[ $return_code -eq 0 ]]; then
        # Load into Rootful ${PODMAN}
        ID=$(${SUDOIF} ${PODMAN} images --filter reference="${target_image}:${tag}" --format "'{{ '{{.ID}}' }}'")
        if [[ -z "$ID" ]]; then
            COPYTMP=$(mktemp -p "${PWD}" -d -t _build_podman_scp.XXXXXXXXXX)
            ${SUDOIF} TMPDIR=${COPYTMP} ${PODMAN} image scp ${UID}@localhost::"${target_image}:${tag}" root@localhost::"${target_image}:${tag}"
            rm -rf "${COPYTMP}"
        fi
    else
        # Make sure the image is present and/or up to date
        ${SUDOIF} ${PODMAN} pull "${target_image}:${tag}"
    fi

_build-bib $flavor $repo $tag $type $config: (rootful-load-image flavor repo tag)
    #!/usr/bin/env bash
    set -euo pipefail

    mkdir -p "output"

    echo "Cleaning up previous build"
    if [[ $type == iso ]]; then
      sudo rm -rf "output/bootiso" || true
    else
      sudo rm -rf "output/${type}" || true
    fi

    target_image="${repo}/$(just get-image-name ${flavor})"

    args="--type ${type}"

    if [[ $target_image == localhost/* ]]; then
      args+=" --local"
    fi

    sudo ${PODMAN} run \
      --rm \
      -it \
      --privileged \
      --pull=newer \
      --net=host \
      --security-opt label=type:unconfined_t \
      -v $(pwd)/${config}:/config.toml:ro \
      -v $(pwd)/output:/output \
      -v /var/lib/containers/storage:/var/lib/containers/storage \
      "${bib_image}" \
      --rootfs btrfs \
      ${args} \
      "${target_image}"

    sudo chown -R $USER:$USER output

_rebuild-bib $flavor $repo $tag $type $config: (build flavor tag) && (_build-bib flavor repo tag type config)

[group('Build Virtual Machine Image')]
build-qcow2 $flavor=image_flavor $repo='localhost' $tag=default_tag: && (_build-bib flavor repo tag "qcow2" "image.toml")

[group('Build Virtual Machine Image')]
build-raw $flavor=image_flavor $repo='localhost' $tag=default_tag: && (_build-bib flavor repo tag "raw" "image.toml")

[group('Build Virtual Machine Image')]
build-iso $flavor=image_flavor $repo='localhost' $tag=default_tag: && (_build-bib flavor repo tag "iso" "iso.toml")

[group('Build Virtual Machine Image')]
rebuild-qcow2 $flavor=image_flavor $repo='localhost' $tag=default_tag: && (_rebuild-bib flavor repo tag "qcow2" "image.toml")

[group('Build Virtual Machine Image')]
rebuild-raw $flavor=image_flavor $repo='localhost' $tag=default_tag: && (_rebuild-bib flavor repo tag "raw" "image.toml")

[group('Build Virtual Machine Image')]
rebuild-iso $flavor=image_flavor $repo='localhost' $tag=default_tag: && (_rebuild-bib flavor repo tag "iso" "iso.toml")

_run-vm $flavor $repo $tag $type $config:
    #!/usr/bin/bash
    set -eoux pipefail

    image_file="output/${type}/disk.${type}"

    if [[ $type == iso ]]; then
        image_file="output/bootiso/install.iso"
    fi

    if [[ ! -f "${image_file}" ]]; then
        just "build-${type}" "$flavor" "$repo" "$tag"
    fi

    # Determine which port to use
    port=8006;
    while grep -q :${port} <<< $(ss -tunalp); do
        port=$(( port + 1 ))
    done
    echo "Using Port: ${port}"
    echo "Connect to http://localhost:${port}"
    run_args=()
    run_args+=(--rm -it --privileged)
    run_args+=(--pull=newer)
    run_args+=(--publish "127.0.0.1:${port}:8006")
    run_args+=(--env "CPU_CORES=4")
    run_args+=(--env "RAM_SIZE=8G")
    run_args+=(--env "DISK_SIZE=64G")
    # run_args+=(--env "BOOT_MODE=windows_secure")
    run_args+=(--env "TPM=Y")
    run_args+=(--env "GPU=Y")
    run_args+=(--device=/dev/kvm)
    run_args+=(--volume "${PWD}/${image_file}":"/boot.${type}")
    run_args+=(docker.io/qemux/qemu-docker)
    (sleep 1; xdg-open http://localhost:${port}) &
    ${PODMAN} run "${run_args[@]}"

[group('Run Virtual Machine')]
run-vm-qcow2 $flavor=image_flavor $repo='localhost' $tag=default_tag: && (_run-vm flavor repo tag "qcow2" "image.toml")

[group('Run Virtual Machine')]
run-vm-raw $flavor=image_flavor $repo='localhost' $tag=default_tag: && (_run-vm flavor repo tag "raw" "image.toml")

[group('Run Virtual Machine')]
run-vm-iso $flavor=image_flavor $repo='localhost' $tag=default_tag: && (_run-vm flavor repo tag "iso" "iso.toml")
