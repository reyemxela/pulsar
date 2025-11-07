#!/usr/bin/bash

set -ouex pipefail

# docker zsh completions
docker completion zsh >/usr/share/zsh/site-functions/_docker


# fix netbird /var/log issues
# https://github.com/netbirdio/netbird/issues/3866#issuecomment-3504960886
sed -i '/^Standard\(Output\|Error\)=/d' /etc/systemd/system/netbird.service