#!/bin/bash

IMAGE_NAME=kinoite
IMAGE_SUFFIX=main
FEDORA_VERSION=41
IMAGE_REPO=ghcr.io/reyemxela

INSTALLER_VARIANT=kinoite


rm -i deploy.iso*

sudo buildah build \
  --build-arg IMAGE_NAME=$IMAGE_NAME \
  --build-arg IMAGE_SUFFIX=$IMAGE_SUFFIX \
  --build-arg FEDORA_MAJOR_VERSION=$FEDORA_VERSION \
  --tag iso-build:latest

sudo podman run --rm --privileged \
  --volume isocache:/cache \
  --volume .:/build-container-installer/build \
  --volume /var/lib/containers/storage:/var/lib/containers/storage \
  ghcr.io/jasonn3/build-container-installer:latest \
  DNF_CACHE=/cache/dnf \
  VERSION=$FEDORA_VERSION \
  IMAGE_SRC=containers-storage:localhost/iso-build:latest \
  IMAGE_NAME=${IMAGE_NAME}${IMAGE_SUFFIX:+-$IMAGE_SUFFIX} \
  IMAGE_TAG=latest \
  IMAGE_REPO=$IMAGE_REPO \
  VARIANT=$INSTALLER_VARIANT

sudo chown $USER:$USER deploy.iso*


cat << EOF

---
ISO created. To create a test VM, run:

virt-install --connect qemu:///system --name fedora${FEDORA_VERSION} --memory 4096 --vcpus 2 --disk size=20 --cdrom ${PWD}/deploy.iso --os-variant fedora${FEDORA_VERSION}

EOF