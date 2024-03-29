#!/bin/bash

set -ouex pipefail

systemctl enable sshd.service
systemctl enable libvirtd.service
systemctl enable tailscaled.service

sed -i 's@SHELL=.*@SHELL=/usr/bin/zsh@' /etc/default/useradd