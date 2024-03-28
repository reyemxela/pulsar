#!/bin/bash

set -ouex pipefail

# exit if this image is in "skip" array
jq -e ".skip | index(\"$IMAGE_NAME\")" /tmp/flatpaks.json >/dev/null && exit 0

INSTALL_FILE_DIR="/usr/share/ublue-os/flatpaks"
INSTALL_FILE="$INSTALL_FILE_DIR/install"
mkdir -p "$INSTALL_FILE_DIR"

# combine "all" and "$IMAGE_NAME" entries, subtracting excluded ones
jq -r "[(.include | (select(.all != null).all, select(.\"$IMAGE_NAME\" != null).\"$IMAGE_NAME\")[])] - \
       [(.exclude | (select(.all != null).all, select(.\"$IMAGE_NAME\" != null).\"$IMAGE_NAME\")[])] \
       | sort | unique[]" \
       /tmp/flatpaks.json > "$INSTALL_FILE"