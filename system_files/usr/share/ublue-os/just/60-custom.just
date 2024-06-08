# Include some of your custom scripts here!

enable-linger USER="$USER":
  sudo loginctl enable-linger {{ USER }}

allow-low-ports:
  echo 'net.ipv4.ip_unprivileged_port_start = 0' |sudo tee /etc/sysctl.d/99-lowports.conf >/dev/null
  sudo sysctl -q --system

configure-mangohud:
  #!/usr/bin/bash
  set -euo pipefail
  cp -R /usr/share/ublue-os/mangohud-config/MangoHud ~/.config
  cp -R /usr/share/ublue-os/mangohud-config/environment.d ~/.config
  echo "Log out to apply environment changes"