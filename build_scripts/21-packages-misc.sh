#!/usr/bin/bash

set -ouex pipefail

# set up ubi
UBI_URL="$(curl -sSL https://api.github.com/repos/houseabsolute/ubi/releases/latest |
  jq -r '.assets[] |select(.name |endswith("ubi-Linux-musl-x86_64.tar.gz")) |.browser_download_url')"
curl -sSL "$UBI_URL" |tar xz --no-same-owner -C /usr/bin ubi


# install packages
ubi -i /usr/bin -p eza-community/eza
ubi -i /usr/bin -p containers/podlet
ubi -i /usr/bin -p michel-kraemer/zsh-patina


# eza completions
TMPDIR="$(mktemp -d)"
ubi -i "$TMPDIR" -p eza-community/eza -r 'completions-.*.tar.gz' --extract-all
mv "$TMPDIR"/completions-*/eza /usr/share/bash-completion/completions/
mv "$TMPDIR"/completions-*/_eza /usr/share/zsh/site-functions/