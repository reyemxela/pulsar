#!/bin/bash

set -ouex pipefail


# nerd fonts
FONT_DIR=/usr/share/fonts/nerd-fonts
mkdir -p "$FONT_DIR/Hack"
FILE='Hack.tar.xz'
curl -sSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$FILE" -o "/tmp/$FILE"
tar xJf "/tmp/$FILE" -C "$FONT_DIR/Hack"
rm -f "/tmp/$FILE"
fc-cache -f "$FONT_DIR/Hack"


# adapta KDE theme
if [[ -d /usr/share/plasma ]]; then # only run on KDE images
  TMPFILE="/tmp/adapta.tar.gz"
  TMPDIR="/tmp/adapta"
  mkdir -p "$TMPDIR"

  curl -sSL https://github.com/PapirusDevelopmentTeam/adapta-kde/archive/master.tar.gz -o "$TMPFILE"
  if ! tar -xzf "$TMPFILE" --no-same-permissions -C "$TMPDIR"; then
    if ! tar -xzf "$TMPFILE" --no-same-owner -C "$TMPDIR"; then
      if ! tar -xzf "$TMPFILE" --no-same-permissions --no-same-owner -C "$TMPDIR"; then
        TMPDIR=$(mktemp -d)
        tar -xzf "$TMPFILE" --no-same-permissions --no-same-owner -C "$TMPDIR"
      fi
    fi
  fi

  cp -R \
    "$TMPDIR/adapta-kde-master/aurorae" \
    "$TMPDIR/adapta-kde-master/color-schemes" \
    "$TMPDIR/adapta-kde-master/konsole" \
    "$TMPDIR/adapta-kde-master/plasma" \
    /usr/share

  rm -rf "$TMPFILE" "$TMPDIR"
fi