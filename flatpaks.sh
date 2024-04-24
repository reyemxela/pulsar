#!/bin/bash

set -ouex pipefail

# exit if this image is in "skip" array
jq -e ".skip | index(\"$IMAGE_NAME\")" /tmp/flatpaks.json >/dev/null && exit 0

mkdir -p /usr/etc/flatpak/remotes.d
curl -sSL https://dl.flathub.org/repo/flathub.flatpakrepo -o /usr/etc/flatpak/remotes.d/flathub.flatpakrepo

INSTALL_FILE_DIR="/usr/share/ublue-os/flatpak"
INSTALL_FILE="$INSTALL_FILE_DIR/install"

mkdir -p "$INSTALL_FILE_DIR"
rm -f "$INSTALL_FILE"

if [[ $IMAGE_NAME = 'bazzite' ]]; then
  # commandeer bazzite's default lists and use with our generic manager
  cp /usr/share/ublue-os/bazzite/flatpak/* "$INSTALL_FILE_DIR"
  systemctl mask bazzite-flatpak-manager.service
fi

systemctl enable ublue-flatpak-manager.service
systemctl disable flatpak-add-fedora-repos.service 2>/dev/null || true

# combine "all" and "$IMAGE_NAME" entries, subtracting excluded ones
jq -r "[(.include | (select(.all != null).all, select(.\"$IMAGE_NAME\" != null).\"$IMAGE_NAME\")[])] - \
       [(.exclude | (select(.all != null).all, select(.\"$IMAGE_NAME\" != null).\"$IMAGE_NAME\")[])] \
       | sort | unique[]" \
       /tmp/flatpaks.json >> "$INSTALL_FILE" # append in the case of existing file (bazzite)