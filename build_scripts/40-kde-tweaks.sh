#!/usr/bin/bash

if [[ ! -d /usr/share/plasma ]]; then # only run on KDE images
  exit
fi

set -ouex pipefail


# adapta KDE theme
TMPFILE="$(mktemp)"
TMPDIR="$(mktemp -d)"

curl -sSL https://github.com/PapirusDevelopmentTeam/adapta-kde/archive/master.tar.gz -o "$TMPFILE"
tar -xzf "$TMPFILE" --no-same-owner --no-same-permissions -C "$TMPDIR"

cp -R \
  "$TMPDIR/adapta-kde-master/aurorae" \
  "$TMPDIR/adapta-kde-master/color-schemes" \
  "$TMPDIR/adapta-kde-master/konsole" \
  "$TMPDIR/adapta-kde-master/plasma" \
  /usr/share

rm -rf "$TMPFILE" "$TMPDIR"

# switch-to-previous-desktop script
TMPFILE="$(mktemp)"
TMPDIR="$(mktemp -d)"

curl -sSL https://invent.kde.org/vladz/switch-to-previous-desktop/-/archive/master/switch-to-previous-desktop-master.tar.gz -o "$TMPFILE"
tar -xzf "$TMPFILE" --no-same-owner --no-same-permissions -C "$TMPDIR"

kpackagetool6 --type=KWin/Script -g -i "$TMPDIR/switch-to-previous-desktop-master/package"

rm -rf "$TMPFILE" "$TMPDIR"

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

ln -sf /usr/share/wallpapers/Pulsar.jpg /usr/share/backgrounds/default.png
ln -sf /usr/share/wallpapers/Pulsar.jpg /usr/share/backgrounds/default-dark.png

# taskbar icons
sed -i '/<entry name="launchers" type="StringList">/,/<\/entry>/ s!<default>[^<]*</default>!<default>preferred://browser,preferred://filemanager,applications:systemsettings.desktop,applications:Alacritty-distrobox.desktop,applications:Alacritty.desktop,applications:code.desktop,applications:org.kde.discover.desktop,applications:steam.desktop</default>!' /usr/share/plasma/plasmoids/org.kde.plasma.taskmanager/contents/config/main.xml

# app menu favorites
sed -i '/<entry name="favorites" type="StringList">/,/<\/entry>/ s!<default>[^<]*</default>!<default>preferred://browser,steam.desktop,systemsettings.desktop,org.kde.dolphin.desktop,org.kde.kate.desktop,Alacritty-distrobox.desktop,Alacritty.desktop,org.kde.discover.desktop,virt-manager.desktop,org.videolan.VLC.desktop,system-update.desktop</default>!' /usr/share/plasma/plasmoids/org.kde.plasma.kickoff/contents/config/main.xml
