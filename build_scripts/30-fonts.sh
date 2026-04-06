#!/usr/bin/bash

set -ouex pipefail

# nerd fonts
FONT_DIR=/usr/share/fonts/nerd-fonts
mkdir -p "$FONT_DIR/Hack"

curl -sSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.tar.xz" |tar xJ -C "$FONT_DIR/Hack"
fc-cache -f "$FONT_DIR/Hack"
