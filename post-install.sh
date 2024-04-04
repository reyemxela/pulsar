#!/bin/bash

set -ouex pipefail

systemctl enable sshd.service
systemctl enable tailscaled.service

systemctl enable libvirtd.service 2>/dev/null || true

sed -i 's@SHELL=.*@SHELL=/usr/bin/zsh@' /etc/default/useradd