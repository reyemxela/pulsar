#!/usr/bin/bash

set -ouex pipefail

# eza
TMPDIR="$(mktemp -d)"

cd "$TMPDIR"
wget -c https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz -O - | tar xz
sudo chmod +x eza
sudo chown root:root eza
sudo mv eza /usr/bin/eza

git clone https://github.com/eza-community/eza.git
mv eza/completions/zsh/* /usr/share/zsh/site-functions/
mv eza/completions/bash/* /usr/share/bash-completion/completions/

cd /
rm -rf "$TMPDIR"
