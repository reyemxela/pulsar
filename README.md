# ublue-custom
[![build-ublue-custom](https://github.com/reyemxela/ublue-custom/actions/workflows/build.yml/badge.svg)](https://github.com/reyemxela/ublue-custom/actions/workflows/build.yml)

My own custom [ublue](https://github.com/ublue-os/)-based Fedora immutable images, with a few little tweaks and extra packages thrown in.

## Features

### Flatpaks
On graphical images, a flatpak installer helper (`system-flatpak-setup.service`) is installed and set to run on boot. The script removes any default fedora repos and sets up flathub, as well as installing any specified apps.

Since the apps in the install file (`/usr/share/ublue-os/flatpaks/install`) are checked and (re-)installed every time the script runs, this list is kept very minimal. It mainly consists of the bare essentials like Firefox/Okular/Gwenview/etc.

### Applications
Along with some handy CLI tools, there are a few GUI applications layered as well. Whenever possible, flatpaks are preferred for GUI apps. However some things don't work well (or at all) as flatpaks, so those are layered.

For example:
- Alacritty
- Virtual Machine Manager
- VSCode
- Wireshark

### Extras
There are a few other extras and tweaks added to the images:

- **All:**
  - `zsh` set as default shell for new users
  - A few additional `just` commands
- **Graphical images:**
  - Include a tweaked `Alacritty-distrobox.desktop` file for distinct host/distrobox shortcuts and sessions
- **Plasma-based images:**
  - [Adapta Nokto](https://github.com/PapirusDevelopmentTeam/adapta-kde) theme installed system-wide
  - Various Plasma settings tweaked in `/etc/skel` for new users:
    - Adapta Nokto as default theme
    - Keyboard shortcuts for window/desktop management
