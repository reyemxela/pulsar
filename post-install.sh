#!/bin/bash

set -ouex pipefail

systemctl enable sshd.service
systemctl enable libvirtd.service
systemctl enable tailscaled.service