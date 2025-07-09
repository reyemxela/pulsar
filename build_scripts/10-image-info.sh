#!/usr/bin/bash

set -ouex pipefail

mkdir -p /usr/share/pulsar

IMAGE_FLAVOR="${IMAGE_NAME/pulsar-/}"
IMAGE_NAME="${IMAGE_NAME/-main/}"

IMAGE_PRETTY_NAME="Pulsar"
IMAGE_LIKE="fedora"
HOME_URL="https://github.com/${IMAGE_VENDOR}/pulsar"
DOCUMENTATION_URL="https://github.com/${IMAGE_VENDOR}/pulsar"
SUPPORT_URL="https://github.com/${IMAGE_VENDOR}/pulsar"
BUG_SUPPORT_URL="https://github.com/${IMAGE_VENDOR}/pulsar/issues/"

LOGO_ICON="pulsar-logo-icon"
LOGO_COLOR="0;38;2;38;57;79"
CODE_NAME=""

IMAGE_INFO="/usr/share/pulsar/image-info.json"
IMAGE_REF="ostree-image-signed:docker://ghcr.io/${IMAGE_VENDOR}/${IMAGE_NAME}"

VERSION_TAG="${MAJOR_VERSION}.$(date '+%Y%m%d')"
VERSION_PRETTY="F${VERSION_TAG}-${IMAGE_FLAVOR}"

# Image Info File
cat > $IMAGE_INFO <<EOF
{
  "image-name": "pulsar",
  "image-flavor": "$IMAGE_FLAVOR",
  "image-vendor": "$IMAGE_VENDOR",
  "image-ref": "$IMAGE_REF",
  "base-image-name": "$BASE_IMAGE",
  "fedora-version": "$MAJOR_VERSION",
  "version": "$VERSION_TAG",
  "version-pretty": "$VERSION_PRETTY"
}
EOF

# OS Release File
sed -i "/^REDHAT_.*=/d; /^BUILD_ID=/d; /^BOOTLOADER_NAME=/d; /^ID_LIKE=/d" /usr/lib/os-release
sed -i "s/^VARIANT_ID=.*/VARIANT_ID=$IMAGE_NAME/" /usr/lib/os-release
sed -i "s/^PRETTY_NAME=.*/PRETTY_NAME=\"Pulsar $MAJOR_VERSION (FROM ${BASE_IMAGE^})\"/" /usr/lib/os-release
sed -i "s/^NAME=.*/NAME=\"$IMAGE_PRETTY_NAME\"/" /usr/lib/os-release
sed -i "s|^HOME_URL=.*|HOME_URL=\"$HOME_URL\"|" /usr/lib/os-release
sed -i "s|^DOCUMENTATION_URL=.*|DOCUMENTATION_URL=\"$DOCUMENTATION_URL\"|" /usr/lib/os-release
sed -i "s|^SUPPORT_URL=.*|SUPPORT_URL=\"$SUPPORT_URL\"|" /usr/lib/os-release
sed -i "s|^BUG_REPORT_URL=.*|BUG_REPORT_URL=\"$BUG_SUPPORT_URL\"|" /usr/lib/os-release
sed -i "s|^CPE_NAME=\"cpe:/o:fedoraproject:fedora|CPE_NAME=\"cpe:/o:${IMAGE_VENDOR}:${IMAGE_PRETTY_NAME,}|" /usr/lib/os-release
sed -i "s/^DEFAULT_HOSTNAME=.*/DEFAULT_HOSTNAME=\"${IMAGE_PRETTY_NAME,}\"/" /usr/lib/os-release
sed -i "s/^ID=.*/ID=${IMAGE_PRETTY_NAME,}\nID_LIKE=\"${IMAGE_LIKE}\"/" /usr/lib/os-release
sed -i "s/^LOGO=.*/LOGO=$LOGO_ICON/" /usr/lib/os-release
sed -i "s/^ANSI_COLOR=.*/ANSI_COLOR=\"$LOGO_COLOR\"/" /usr/lib/os-release
sed -i "s|^VERSION_CODENAME=.*|VERSION_CODENAME=\"$CODE_NAME\"|" /usr/lib/os-release

echo "BUILD_ID=\"$VERSION_PRETTY\"" >> /usr/lib/os-release
echo "BOOTLOADER_NAME=\"$IMAGE_PRETTY_NAME ($VERSION_PRETTY)\"" >> /usr/lib/os-release

# Fix issues caused by ID no longer being fedora
sed -i "s/^EFIDIR=.*/EFIDIR=\"fedora\"/" /usr/sbin/grub2-switch-to-blscfg