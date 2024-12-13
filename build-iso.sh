#!/bin/bash

IMAGE_NAME=bazzite
IMAGE_SUFFIX=
FEDORA_VERSION=41
IMAGE_REPO=ghcr.io/reyemxela

INSTALLER_VARIANT=kinoite

FULL_IMAGE_NAME=${IMAGE_NAME}${IMAGE_SUFFIX:+-$IMAGE_SUFFIX}

rm -i deploy.iso*

sudo buildah build \
  --build-arg IMAGE_NAME=$IMAGE_NAME \
  --build-arg IMAGE_SUFFIX=$IMAGE_SUFFIX \
  --build-arg FEDORA_MAJOR_VERSION=$FEDORA_VERSION \
  --tag iso-build:latest

if [ $? -ne 0 ]; then
  exit 1
fi

sudo podman run --rm --privileged \
  --volume isocache:/cache \
  --volume .:/build-container-installer/build \
  --volume /var/lib/containers/storage:/var/lib/containers/storage \
  ghcr.io/jasonn3/build-container-installer:latest \
  DNF_CACHE=/cache/dnf \
  VERSION=$FEDORA_VERSION \
  IMAGE_SRC=containers-storage:localhost/iso-build:latest \
  IMAGE_NAME=$FULL_IMAGE_NAME \
  IMAGE_TAG=latest \
  IMAGE_REPO=$IMAGE_REPO \
  VARIANT=$INSTALLER_VARIANT

sudo chown $USER:$USER deploy.iso*


cat << EOF

---
ISO created. To create a test VM, run:

virt-install --connect qemu:///system --name ${FULL_IMAGE_NAME}_$(date '+%Y%m%d-%H%M%S') --memory 4096 --vcpus 2 --disk size=20 --cdrom ${PWD}/deploy.iso --os-variant $(virt-install --osinfo list |grep -i fedora |head -1)

EOF