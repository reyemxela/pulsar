#!/usr/bin/bash

set -ouex pipefail

# disables
systemctl disable bazzite-flatpak-manager.service || true
systemctl disable ublue-flatpak-manager.service || true
systemctl disable ublue-update.service || true

# enables
systemctl enable sshd.service
systemctl enable tailscaled.service
systemctl enable libvirtd.service 2>/dev/null || true

systemctl enable pulsar-first-run.service

systemctl --global enable copy-themes.service

# flatpaks
if [ -f /usr/share/pulsar/flatpak/install ]; then
  systemctl enable pulsar-flatpak-manager.service
fi

# updates
if [[ $IMAGE_FLAVOR != "deck" ]]; then
  # let deck behave normally, everything else gets auto updates
  systemctl enable bootc-fetch-apply-updates.timer
fi