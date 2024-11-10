# Include some of your custom scripts here!

enable-linger USER="$USER":
  sudo loginctl enable-linger {{ USER }}

allow-low-ports:
  echo 'net.ipv4.ip_unprivileged_port_start = 0' |sudo tee /etc/sysctl.d/99-lowports.conf >/dev/null
  sudo sysctl -q --system

configure-mangohud:
  #!/usr/bin/bash
  set -euo pipefail
  mkdir -p ~/.config ~/.local/share/applications
  cp -R /usr/share/ublue-os/mangohud-config/MangoHud ~/.config
  sed 's!^Exec=\(/usr/bin/bazzite-steam.*\)!Exec=/usr/bin/mangohud \1!' /usr/share/applications/steam.desktop >~/.local/share/applications/steam.desktop
  update-desktop-database
  echo "Relaunch Steam to apply changes"

add-to-group GROUP="" USER="$USER":
  #!/usr/bin/bash

  group="{{ GROUP }}"
  user="{{ USER }}"

  if [[ -z $group ]]; then
    echo "Please specify a group"
    exit 1
  fi

  if ! grep -q "^${group}:" /etc/group; then
    line="$(getent group $group)"
    if [[ -z $line ]]; then
      echo "Group '$group' not found"
      exit 1
    fi
    sudo bash -c "echo '$line' >> /etc/group"
  fi

  sudo usermod -aG "$group" "$user"

fix-hardware-cursor:
  #!/usr/bin/bash
  mkdir -p "$HOME/.config/environment.d"
  echo 'HIDE_CURSOR_DELAY_MS=99999' > "$HOME/.config/environment.d/hidecursor.conf"