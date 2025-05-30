#!/usr/bin/bash

set -ouex pipefail

# clean up autostarts
rm -f /etc/skel/.config/autostart/steam.desktop
rm -f /etc/profile.d/ublue-firstboot.sh
rm -f /etc/profile.d/user-motd.sh

# rechunk quirks
if [[ -e /usr/bin/sunshine ]]; then
  setcap cap_sys_admin+p "$(readlink -f /usr/bin/sunshine)"
fi

if [[ -e /usr/bin/gamescope ]]; then
  setcap cap_sys_nice=eip /usr/bin/gamescope
fi

# merge /usr/etc into /etc
cp -ar /usr/etc / 2>/dev/null || true
rm -rf /usr/etc