#!/usr/bin/bash

if [[ ! -e /usr/bin/plasmashell ]]; then # only run on KDE images
  exit
fi

set -ouex pipefail

# fix kpackagetool6 breaking if the scripts folder doesn't exist
mkdir -p /usr/share/kwin/scripts

# adapta KDE theme
TMPDIR="$(mktemp -d)"

curl -sSL https://github.com/PapirusDevelopmentTeam/adapta-kde/archive/master.tar.gz |
  tar xzf --no-same-owner --no-same-permissions -C "$TMPDIR"

cp -R \
  "$TMPDIR/adapta-kde-master/aurorae" \
  "$TMPDIR/adapta-kde-master/color-schemes" \
  "$TMPDIR/adapta-kde-master/konsole" \
  "$TMPDIR/adapta-kde-master/plasma" \
  /usr/share

rm -rf "$TMPDIR"

# switch-to-previous-desktop script
TMPDIR="$(mktemp -d)"

curl -sSL https://invent.kde.org/vladz/switch-to-previous-desktop/-/archive/master/switch-to-previous-desktop-master.tar.gz |
  tar xzf --no-same-owner --no-same-permissions -C "$TMPDIR"

kpackagetool6 --type=KWin/Script -g -i "$TMPDIR/switch-to-previous-desktop-master/package"

rm -rf "$TMPDIR"

# add dynamicwallpaperconverter to accompany plasma-wallpapers-dynamic
curl -sSL https://raw.githubusercontent.com/zzag/plasma5-wallpapers-dynamic-extras/master/dynamicwallpaperconverter -o /usr/bin/dynamicwallpaperconverter
chmod +x /usr/bin/dynamicwallpaperconverter

# change default keybinds
sed -i 's/\(X-KDE-Shortcuts=.*\),Meta+Shift+S/\1/g' /usr/share/kglobalaccel/org.kde.spectacle.desktop
sed -i '/\[Desktop Action RectangularRegionScreenShot\]/,/^\[/ s/\(X-KDE-Shortcuts=.*\)/\1,Meta+Shift+S/g' /usr/share/kglobalaccel/org.kde.spectacle.desktop

if [[ -e /usr/bin/alacritty ]]; then
  # replace stock icon with included ones
  rm -f /usr/share/pixmaps/Alacritty.svg

  # copy default .desktop file to make a distrobox one, change settings and add KDE shortcuts
  cp /usr/share/applications/Alacritty.desktop /usr/share/applications/Alacritty-distrobox.desktop
  sed -i 's/\[Desktop Action New\]/\[Desktop Action New\]\nX-KDE-Shortcuts=Meta+Shift+Return/g' /usr/share/applications/Alacritty.desktop
  sed -i 's/\[Desktop Action New\]/\[Desktop Action New\]\nX-KDE-Shortcuts=Meta+Return/g' /usr/share/applications/Alacritty-distrobox.desktop
  sed -i 's/^Exec=alacritty/Exec=alacritty -T "Alacritty \(distrobox\)" --class "Alacritty \(distrobox\)" -e distrobox-enter/g' /usr/share/applications/Alacritty-distrobox.desktop
  sed -i 's/^\(Name\|StartupWMClass\)=Alacritty/\1=Alacritty \(distrobox\)/g' /usr/share/applications/Alacritty-distrobox.desktop

  sed -i 's/Icon=Alacritty/Icon=Alacritty-blue/g' /usr/share/applications/Alacritty-distrobox.desktop

  ln -s /usr/share/applications/Alacritty.desktop /usr/share/kglobalaccel/Alacritty.desktop
  ln -s /usr/share/applications/Alacritty-distrobox.desktop /usr/share/kglobalaccel/Alacritty-distrobox.desktop
fi

rm -f /usr/share/backgrounds/default{,-dark}.jxl
rm -f /usr/share/backgrounds/default.xml

ln -sf /usr/share/wallpapers/Pulsar.jpg /usr/share/backgrounds/default.jxl
ln -sf /usr/share/wallpapers/Pulsar.jpg /usr/share/backgrounds/default-dark.jxl

rm -f /usr/share/plasma/shells/org.kde.plasma.desktop/contents/updates/bazzite-pins.js