#!/usr/bin/bash

set -ouex pipefail

mkdir -p /usr/share/pulsar/flatpak

shared="\
org.mozilla.firefox
org.kde.gwenview
org.kde.okular
org.kde.kcalc
org.kde.filelight
it.mijorus.gearlever
com.github.tchx84.Flatseal
org.videolan.VLC
com.github.zocker_160.SyncThingy
"

if [[ $IMAGE_FLAVOR = "main" || $IMAGE_FLAVOR = "deck" ]]; then
  echo $shared >/usr/share/pulsar/flatpak/install
fi
