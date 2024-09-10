#!/bin/bash

set -ouex pipefail

systemctl enable sshd.service
systemctl enable tailscaled.service
systemctl enable libvirtd.service 2>/dev/null || true

# let bazzite-deck continue to use its tweaked update system,
# everything else use rpm-ostreed-automatic/flatpak-system-update
if [[ $FULL_IMAGE_NAME = 'bazzite-deck' ]]; then
  systemctl disable flatpak-system-update.timer
else
  sed -i 's/AutomaticUpdatePolicy=.*/AutomaticUpdatePolicy=stage/' /etc/rpm-ostreed.conf
  systemctl disable ublue-update.timer 2>/dev/null || true
  systemctl enable rpm-ostreed-automatic.timer
  systemctl enable flatpak-system-update.timer
fi

# rechunk quirks
if [[ -e /usr/bin/sunshine ]]; then
  setcap cap_sys_admin+p "$(readlink -f /usr/bin/sunshine)"
fi

if [[ -e /usr/bin/gamescope ]]; then
  setcap cap_sys_nice=eip /usr/bin/gamescope
fi