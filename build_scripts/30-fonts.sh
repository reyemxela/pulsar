#!/usr/bin/bash

set -ouex pipefail

# nerd fonts
FONT_DIR=/usr/share/fonts/nerd-fonts
mkdir -p "$FONT_DIR/Hack"

TMPFILE="$(mktemp)"
curl -sSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.tar.xz" -o "$TMPFILE"
tar xJf "$TMPFILE" -C "$FONT_DIR/Hack"
rm -f "$TMPFILE"
fc-cache -f "$FONT_DIR/Hack"
