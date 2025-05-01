export repo_organization := env("GITHUB_REPOSITORY_OWNER", "reyemxela")
export image_flavor := env("IMAGE_FLAVOR", "main")
export major_version := env("MAJOR_VERSION", "41")
export default_tag := env("DEFAULT_TAG", "latest")
export bib_image := env("BIB_IMAGE", "quay.io/centos-bootc/bootc-image-builder:latest")

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
    rm -rf output/

# Sudo Clean Repo
[group('Utility')]
[private]
sudo-clean:
    just sudoif just clean

# sudoif bash function
[group('Utility')]
[private]
sudoif command *args:
    #!/usr/bin/bash
    function sudoif(){
        if [[ "${UID}" -eq 0 ]]; then
            "$@"
        elif [[ "$(command -v sudo)" && -n "${SSH_ASKPASS:-}" ]] && [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]; then
            /usr/bin/sudo --askpass "$@" || exit 1
        elif [[ "$(command -v sudo)" ]]; then
            /usr/bin/sudo "$@" || exit 1
        else
            exit 1
        fi
    }
    sudoif {{ command }} {{ args }}

[group('Utility')]
[private]
get-image-name $flavor=image_flavor:
    #!/usr/bin/env bash
    IMAGE_NAME="pulsar-${flavor}"
    echo "${IMAGE_NAME/-main/}"

[group('Utility')]
[private]
get-base-image $flavor=image_flavor:
    #!/usr/bin/env bash
    set -euo pipefail

    declare -A base_images={{ base_images }}
    echo "${base_images[$flavor]}"

[group('Utility')]
[private]
get-labels $flavor=image_flavor:
    #!/usr/bin/env bash
    set -euo pipefail

    target_image="$(just get-image-name ${flavor})"

    echo "\
    org.opencontainers.image.created=$(date -u +%Y\-%m\-%d\T%H\:%M\:%S\Z)
    org.opencontainers.image.description=Customized Universal Blue images with some extras
    org.opencontainers.image.documentation=https://github.com/${repo_organization}/pulsar
    org.opencontainers.image.source=https://github.com/${repo_organization}/pulsar/blob/main/Containerfile
    org.opencontainers.image.title=${target_image}
    org.opencontainers.image.url=https://github.com/${repo_organization}/pulsar
    org.opencontainers.image.vendor=${repo_organization}
    io.artifacthub.package.readme-url=https://raw.githubusercontent.com/${repo_organization}/pulsar/refs/heads/main/README.md
    io.artifacthub.package.logo-url=https://raw.githubusercontent.com/${repo_organization}/pulsar/refs/heads/main/logo.svg
    io.artifacthub.package.maintainers=[{\"name\":\"reyemxela\",\"email\":\"alexwreyem@gmail.com\"}]
    io.artifacthub.package.keywords=bootc,fedora,pulsar,ublue,universal-blue
    io.artifacthub.package.license=Apache-2.0
    containers.bootc=1
    "

# This Justfile recipe builds a container image using Podman.
#
# Arguments:
#   $target_image - The tag you want to apply to the image (default: aurora).
#   $tag - The tag for the image (default: lts).
#   $dx - Enable DX (default: "0").
#   $hwe - Enable HWE (default: "0").
#   $gdx - Enable GDX (default: "0").
#
# DX:
#   Developer Experience (DX) is a feature that allows you to install the latest developer tools for your system.
#   Packages include VScode, Docker, Distrobox, and more.
# HWE:
#   Hardware Enablement (HWE) is a feature that allows you to install the latest hardware support for your system.
#   Currently this install the Hyperscale SIG kernel which will stay ahead of the CentOS Stream kernel and enables btrfs
# GDX: https://docs.projectaurora.io/gdx/
#   GPU Developer Experience (GDX) creates a base as an AI and Graphics platform.
#   Installs Nvidia drivers, CUDA, and other tools.
#
# The script constructs the version string using the tag and the current date.
# If the git working directory is clean, it also includes the short SHA of the current HEAD.
#
# just build $target_image $tag $dx $hwe $gdx
#
# Example usage:
#   just build aurora lts 1 0 1
#
# This will build an image 'aurora:lts' with DX and GDX enabled.
#

# Build the image using the specified parameters
build $flavor=image_flavor $tag=default_tag:
    #!/usr/bin/env bash
    set -euo pipefail

    base_image="$(just get-base-image ${flavor})"
    target_image="$(just get-image-name ${flavor})"

    BUILD_ARGS=()
    BUILD_ARGS+=("--build-arg" "IMAGE_FLAVOR=${flavor}")
    BUILD_ARGS+=("--build-arg" "IMAGE_VENDOR=${repo_organization}")
    BUILD_ARGS+=("--build-arg" "BASE_IMAGE=${base_image}")
    BUILD_ARGS+=("--build-arg" "MAJOR_VERSION=${major_version}")

    podman build \
        "${BUILD_ARGS[@]}" \
        --pull=newer \
        --tag "${target_image}:${tag}" \
        .

rechunk $flavor=image_flavor $fresh='false' $tag=default_tag:
    #!/usr/bin/env bash

    echo "::group:: Rechunk Build Prep"
    set -eou pipefail

    target_image="$(just get-image-name ${flavor})"

    REF=localhost/${target_image}:${tag}
    RECHUNK=ghcr.io/hhd-dev/rechunk:latest

    ID=$(podman images --filter reference=${REF} --format "'{{ '{{.ID}}' }}'")

    if [[ -z "$ID" ]]; then
        just build $flavor $tag
    fi

    if [[ "${UID}" -gt "0" ]]; then
        COPYTMP="$(mktemp -p "${PWD}" -d -t podman_scp.XXXXXXXXXX)"
        just sudoif TMPDIR="${COPYTMP}" podman image scp "${UID}"@localhost::${REF} root@localhost::${REF}
        rm -rf "${COPYTMP}"
    fi

    CREF=$(just sudoif podman create ${REF} bash)
    MOUNT=$(just sudoif podman mount "$CREF")
    OUT_NAME="${target_image}_${tag}"
    # VERSION="$(just sudoif podman inspect "$CREF" | jq -r '.[]["Config"]["Labels"]["org.opencontainers.image.version"]')"
    VERSION="${major_version}.$(date '+%Y%m%d')"

    echo "::endgroup::"

    echo "::group:: Rechunk Prune"
    just sudoif podman run --rm \
        --security-opt label=disable \
        --volume "$MOUNT":/var/tree \
        --env TREE=/var/tree \
        --user 0:0 \
        ${RECHUNK} \
        /sources/rechunk/1_prune.sh
    echo "::endgroup::"

    echo "::group:: Create Tree"
    just sudoif podman run --rm \
        --security-opt label=disable \
        --volume "$MOUNT":/var/tree \
        --volume "cache_ostree:/var/ostree" \
        --env TREE=/var/tree \
        --env REPO=/var/ostree/repo \
        --env RESET_TIMESTAMP=1 \
        --user 0:0 \
        ${RECHUNK} \
        /sources/rechunk/2_create.sh
    just sudoif podman unmount "$CREF"
    just sudoif podman rm "$CREF"
    if [[ "${UID}" -gt "0" ]]; then
        just sudoif podman rmi ${REF}
    fi
    podman rmi ${REF}
    echo "::endgroup::"

    echo "::group:: Rechunk"
    if [[ $fresh == "true" ]]; then
        PREV_REF=""
    else
        PREV_REF="ghcr.io/${repo_organization}/${target_image}:${tag}"
    fi
    just sudoif podman run --rm \
        --pull=newer \
        --security-opt label=disable \
        --volume "$PWD:/workspace" \
        --volume "$PWD:/var/git" \
        --volume cache_ostree:/var/ostree \
        --env REPO=/var/ostree/repo \
        --env PREV_REF=$PREV_REF \
        --env LABELS="$(just get-labels $flavor)" \
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
    just sudoif find ${target_image}_${tag} -type d -exec chmod 0755 {} \; || true
    just sudoif find ${target_image}_${tag}* -type f -exec chmod 0644 {} \; || true
    if [[ "${UID}" -gt "0" ]]; then
        just sudoif chown -R "${UID}":"${GROUPS[0]}" "${PWD}"
        just _load_image ${flavor} ${tag}
    elif [[ "${UID}" == "0" && -n "${SUDO_USER:-}" ]]; then
        just sudoif chown -R "${SUDO_UID}":"${SUDO_GID}" "/run/user/${SUDO_UID}/just"
        just sudoif chown -R "${SUDO_UID}":"${SUDO_GID}" "${PWD}"
    fi

    just sudoif podman volume rm cache_ostree
    echo "::endgroup::"

_load_image $flavor=image_flavor $tag=default_tag:
    #!/usr/bin/env bash
    set -eou pipefail
    
    target_image="$(just get-image-name ${flavor})"
    OUT_NAME="${target_image}_${tag}"

    IMAGE=$(podman pull oci:${PWD}/$OUT_NAME)
    podman tag ${IMAGE} localhost/${target_image}:${tag}
    for t in $(just get-tags $flavor $tag); do
        podman tag ${IMAGE} localhost/${target_image}:${t}
    done
    podman images
    rm -rf $OUT_NAME

get-tags $flavor=image_flavor $tag=default_tag:
    #!/usr/bin/env bash
    set -eou pipefail
    
    target_image="$(just get-image-name ${flavor})"

    echo "${tag} ${major_version}"

# Command: _rootful_load_image
# Description: This script checks if the current user is root or running under sudo. If not, it attempts to resolve the image tag using podman inspect.
#              If the image is found, it loads it into rootful podman. If the image is not found, it pulls it from the repository.
#
# Parameters:
#   $target_image - The name of the target image to be loaded or pulled.
#   $tag - The tag of the target image to be loaded or pulled. Default is 'default_tag'.
#
# Example usage:
#   _rootful_load_image my_image latest
#
# Steps:
# 1. Check if the script is already running as root or under sudo.
# 2. Check if target image is in the non-root podman container storage)
# 3. If the image is found, load it into rootful podman using podman scp.
# 4. If the image is not found, pull it from the remote repository into reootful podman.

_rootful_load_image $flavor=image_flavor $tag=default_tag:
    #!/usr/bin/bash
    set -eoux pipefail

    # Check if already running as root or under sudo
    if [[ -n "${SUDO_USER:-}" || "${UID}" -eq "0" ]]; then
        echo "Already root or running under sudo, no need to load image from user podman."
        exit 0
    fi

    target_image="$(just get-image-name ${flavor})"

    set +e
    resolved_tag=$(podman inspect -t image "${target_image}:${tag}" | jq -r '.[].RepoTags.[0]')
    return_code=$?
    set -e

    USER_IMG_ID=$(podman images --filter reference="${target_image}:${tag}" --format "'{{ '{{.ID}}' }}'")

    if [[ $return_code -eq 0 ]]; then
        # If the image is found, load it into rootful podman
        ID=$(just sudoif podman images --filter reference="${target_image}:${tag}" --format "'{{ '{{.ID}}' }}'")
        if [[ "$ID" != "$USER_IMG_ID" ]]; then
            # If the image ID is not found or different from user, copy the image from user podman to root podman
            COPYTMP=$(mktemp -p "${PWD}" -d -t _build_podman_scp.XXXXXXXXXX)
            just sudoif TMPDIR=${COPYTMP} podman image scp ${UID}@localhost::"${target_image}:${tag}" root@localhost::"${target_image}:${tag}"
            rm -rf "${COPYTMP}"
        fi
    else
        # If the image is not found, pull it from the repository
        just sudoif podman pull "${target_image}:${tag}"
    fi

# Build a bootc bootable image using Bootc Image Builder (BIB)
# Converts a container image to a bootable image
# Parameters:
#   target_image: The name of the image to build (ex. localhost/fedora)
#   tag: The tag of the image to build (ex. latest)
#   type: The type of image to build (ex. qcow2, raw, iso)
#   config: The configuration file to use for the build (default: image.toml)

# Example: just _rebuild-bib localhost/fedora latest qcow2 image.toml
_build-bib $flavor $tag $type $config: (_rootful_load_image flavor tag)
    #!/usr/bin/env bash
    set -euo pipefail

    target_image="localhost/$(just get-image-name ${flavor})"

    args="--type ${type} "
    args+="--use-librepo=True"

    if [[ $target_image == localhost/* ]]; then
      args+=" --local"
    fi

    BUILDTMP=$(mktemp -p "${PWD}" -d -t _build-bib.XXXXXXXXXX)

    sudo podman run \
      --rm \
      -it \
      --privileged \
      --pull=newer \
      --net=host \
      --security-opt label=type:unconfined_t \
      -v $(pwd)/${config}:/config.toml:ro \
      -v $BUILDTMP:/output \
      -v /var/lib/containers/storage:/var/lib/containers/storage \
      "${bib_image}" \
      ${args} \
      --rootfs btrfs \
      "${target_image}:${tag}"

    mkdir -p output
    sudo mv -f $BUILDTMP/* output/
    sudo rmdir $BUILDTMP
    sudo chown -R $USER:$USER output/

# Podman builds the image from the Containerfile and creates a bootable image
# Parameters:
#   target_image: The name of the image to build (ex. localhost/fedora)
#   tag: The tag of the image to build (ex. latest)
#   type: The type of image to build (ex. qcow2, raw, iso)
#   config: The configuration file to use for the build (deafult: image.toml)

# Example: just _rebuild-bib localhost/fedora latest qcow2 image.toml
_rebuild-bib $flavor $tag $type $config: (build flavor tag) && (_build-bib flavor tag type config)

# Build a QCOW2 virtual machine image
[group('Build Virtual Machine Image')]
build-qcow2 $flavor=image_flavor $tag=default_tag: && (_build-bib flavor tag "qcow2" "image.toml")

# Build a RAW virtual machine image
[group('Build Virtual Machine Image')]
build-raw $flavor=image_flavor $tag=default_tag: && (_build-bib flavor tag "raw" "image.toml")

# Build an ISO virtual machine image
[group('Build Virtual Machine Image')]
build-iso $flavor=image_flavor $tag=default_tag: && (_build-bib flavor tag "iso" "iso.toml")

# Rebuild a QCOW2 virtual machine image
[group('Build Virtual Machine Image')]
rebuild-qcow2 $flavor=image_flavor $tag=default_tag: && (_rebuild-bib flavor tag "qcow2" "image.toml")

# Rebuild a RAW virtual machine image
[group('Build Virtual Machine Image')]
rebuild-raw $flavor=image_flavor $tag=default_tag: && (_rebuild-bib flavor tag "raw" "image.toml")

# Rebuild an ISO virtual machine image
[group('Build Virtual Machine Image')]
rebuild-iso $flavor=image_flavor $tag=default_tag: && (_rebuild-bib flavor tag "iso" "iso.toml")

# Run a virtual machine with the specified image type and configuration
_run-vm $flavor $tag $type $config:
    #!/usr/bin/bash
    set -eoux pipefail

    # Determine the image file based on the type
    image_file="output/${type}/disk.${type}"
    if [[ $type == iso ]]; then
        image_file="output/bootiso/install.iso"
    fi

    # Build the image if it does not exist
    if [[ ! -f "${image_file}" ]]; then
        just "build-${type}" "$flavor" "$tag"
    fi

    # Determine an available port to use
    port=8006
    while grep -q :${port} <<< $(ss -tunalp); do
        port=$(( port + 1 ))
    done
    echo "Using Port: ${port}"
    echo "Connect to http://localhost:${port}"

    # Set up the arguments for running the VM
    run_args=()
    run_args+=(--rm -it --privileged)
    run_args+=(--pull=newer)
    run_args+=(--publish "127.0.0.1:${port}:8006")
    run_args+=(--env "CPU_CORES=4")
    run_args+=(--env "RAM_SIZE=8G")
    run_args+=(--env "DISK_SIZE=64G")
    run_args+=(--env "TPM=Y")
    run_args+=(--env "GPU=Y")
    run_args+=(--device=/dev/kvm)
    run_args+=(--volume "${PWD}/${image_file}":"/boot.${type}")
    run_args+=(docker.io/qemux/qemu-docker)
    
    # Run the VM and open the browser to connect
    # podman run "${run_args[@]}" &
    # xdg-open http://localhost:${port}
    # fg "%podman"
    (sleep 1; xdg-open http://localhost:${port}) &
    podman run "${run_args[@]}"



# Run a virtual machine from a QCOW2 image
[group('Run Virtual Machine')]
run-vm-qcow2 $flavor=image_flavor $tag=default_tag: && (_run-vm flavor tag "qcow2" "image.toml")

# Run a virtual machine from a RAW image
[group('Run Virtual Machine')]
run-vm-raw $flavor=image_flavor $tag=default_tag: && (_run-vm flavor tag "raw" "image.toml")

# Run a virtual machine from an ISO
[group('Run Virtual Machine')]
run-vm-iso $flavor=image_flavor $tag=default_tag: && (_run-vm flavor tag "iso" "iso.toml")

# Run a virtual machine using systemd-vmspawn
[group('Run Virtal Machine')]
spawn-vm $flavor=image_flavor $tag=default_tag rebuild="0" type="qcow2" ram="6G":
    #!/usr/bin/env bash

    set -euo pipefail

    [ "{{ rebuild }}" -eq 1 ] && echo "Rebuilding the ISO" && just rebuild-vm $flavor $tag {{ rebuild }} {{ type }}

    systemd-vmspawn \
      -M "bootc-image" \
      --console=gui \
      --cpus=2 \
      --ram=$(echo {{ ram }}| /usr/bin/numfmt --from=iec) \
      --network-user-mode \
      --vsock=false --pass-ssh-key=false \
      -i ./output/**/*.{{ type }}


# Runs shell check on all Bash scripts
lint:
    /usr/bin/find . -iname "*.sh" -type f -exec shellcheck "{}" ';'

# Runs shfmt on all Bash scripts
format:
    /usr/bin/find . -iname "*.sh" -type f -exec shfmt --write "{}" ';'