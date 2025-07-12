#!/usr/bin/env bash

if [[ ! $IMAGE_FLAVOR =~ "nvidia" ]]; then
  echo "not nvidia image, skipping..."
  exit 0
fi

set -ouex pipefail

KERNEL_BASE="bazzite"
if [[ $IMAGE_FLAVOR =~ "cli" ]]; then
  KERNEL_BASE="main"
fi

skopeo copy --retry-times 3 docker://ghcr.io/ublue-os/akmods-nvidia:"${KERNEL_BASE}"-"$(rpm -E %fedora)" dir:/tmp/akmods-rpms
NVIDIA_TARGZ=$(jq -r '.layers[].digest' </tmp/akmods-rpms/manifest.json | cut -d : -f 2)
tar -xvzf /tmp/akmods-rpms/"$NVIDIA_TARGZ" -C /tmp/
mv /tmp/rpms/* /tmp/akmods-rpms/
find /tmp/akmods-rpms

sed -i '0,/enabled=0/{s/enabled=0/enabled=1/}' /etc/yum.repos.d/negativo17-fedora-multimedia.repo

curl -Lo /tmp/nvidia-install.sh https://raw.githubusercontent.com/ublue-os/main/main/build_files/nvidia-install.sh
chmod +x /tmp/nvidia-install.sh

IMAGE_NAME="kinoite"
if [[ $IMAGE_FLAVOR =~ "cli" ]]; then
  IMAGE_NAME=""
fi
IMAGE_NAME="$IMAGE_NAME" RPMFUSION_MIRROR="" /tmp/nvidia-install.sh

rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json
ln -sf libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so
tee /usr/lib/bootc/kargs.d/00-nvidia.toml <<EOF
kargs = ["rd.driver.blacklist=nouveau", "modprobe.blacklist=nouveau", "nvidia-drm.modeset=1", "initcall_blacklist=simpledrm_platform_driver_init"]
EOF