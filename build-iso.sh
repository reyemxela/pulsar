#!/bin/bash

set -oue pipefail

IMAGE_NAME=pulsar-cli-nvidia
MAJOR_VERSION=42
IMAGE_REPO=ghcr.io/reyemxela

INSTALLER_VARIANT=kinoite

mkdir -p output

rm -f output/deploy.iso*

if [[ ${1-} != "--skipbuild" ]]; then
  sudo just build
fi

ID="$(sudo podman images --filter reference="${IMAGE_NAME}:latest" --format "{{.ID}}")"
if [[ $ID != "" ]]; then
  SRC="containers-storage:${ID}"
else
  SRC="containers-storage:${IMAGE_REPO}/${IMAGE_NAME}:latest"
fi

sudo podman run --rm --privileged \
  --volume isocache:/cache \
  --volume ./output:/build-container-installer/build \
  --volume /var/lib/containers/storage:/var/lib/containers/storage \
  ghcr.io/jasonn3/build-container-installer:latest \
  DNF_CACHE=/cache/dnf \
  VERSION=$MAJOR_VERSION \
  IMAGE_SRC=$SRC \
  IMAGE_NAME=$IMAGE_NAME \
  IMAGE_TAG=latest \
  IMAGE_REPO=$IMAGE_REPO \
  VARIANT=$INSTALLER_VARIANT

sudo chown $USER:$USER output/deploy.iso*

cat << EOF

---
ISO created. To create a test VM, run:

virt-install --connect qemu:///system --name ${IMAGE_NAME}_$(date '+%Y%m%d-%H%M%S') --memory 4096 --vcpus 2 --disk size=30 --cdrom ${PWD}/output/deploy.iso --os-variant $(virt-install --osinfo list |grep -i fedora |head -1)

EOF
