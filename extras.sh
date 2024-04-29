#!/bin/bash

set -ouex pipefail


# nerd fonts
FONT_DIR=/usr/share/fonts/nerd-fonts
mkdir -p "$FONT_DIR/Hack"

TMPFILE="$(mktemp)"
curl -sSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.tar.xz" -o "$TMPFILE"
tar xJf "$TMPFILE" -C "$FONT_DIR/Hack"
rm -f "$TMPFILE"
fc-cache -f "$FONT_DIR/Hack"


if [[ -d /usr/share/plasma ]]; then # only run on KDE images
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
fi