#!/bin/bash

set -ouex pipefail


# nerd fonts
FONT_DIR=/usr/share/fonts/nerd-fonts
mkdir -p "$FONT_DIR/Hack"
FILE='Hack.tar.xz'
wget -O "/tmp/$FILE" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$FILE"
tar xJf "/tmp/$FILE" -C "$FONT_DIR/Hack"
rm -f "/tmp/$FILE"
fc-cache -f "$FONT_DIR/Hack"


# adapta KDE theme
if [[ -d /usr/share/plasma ]]; then # only run on KDE images
  TMPFILE="/tmp/adapta.tar.gz"
  TMPDIR="/tmp/adapta"
  mkdir -p "$TMPDIR"

  wget -O "$TMPFILE" https://github.com/PapirusDevelopmentTeam/adapta-kde/archive/master.tar.gz
  tar -xzf "$TMPFILE" -C "$TMPDIR"

  cp -R \
    "$TMPDIR/adapta-kde-master/aurorae" \
    "$TMPDIR/adapta-kde-master/color-schemes" \
    "$TMPDIR/adapta-kde-master/konsole" \
    "$TMPDIR/adapta-kde-master/plasma" \
    /usr/share

  rm -rf "$TMPFILE" "$TMPDIR"
fi