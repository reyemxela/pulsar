#!/usr/bin/bash

set -ouex pipefail

dnf5 -y copr enable errornointernet/mergerfs
dnf5 -y copr enable ublue-os/staging

shared=(
  "bat"
  "btop"
  "dua-cli"
  "entr"
  "etckeeper"
  "evtest"
  "eza"
  "gh"
  "netcat"
  "nmap"
  "osbuild-selinux"
  "picocom"
  "samba"
  "strace"
  "tailscale"
  "zsh"
)

virt=(
  "guestfs-tools"
  "libvirt"
  "virt-install"
)

server=(
  "mergerfs"
  "snapraid"
)

gui=(
  "alacritty"
  "code"
  "ddccontrol"
  "plasma-wallpapers-dynamic"
  "virt-manager"
  "virt-viewer"
  "wireshark"
)


dnf5 -y install ${shared[@]}

if [[ $IMAGE_FLAVOR = "main" ]]; then
  dnf5 -y install ${virt[@]} ${gui[@]}
elif [[ $IMAGE_FLAVOR = "deck" ]]; then
  dnf5 -y install ${gui[@]}
elif [[ $IMAGE_FLAVOR = "cli" ]]; then
  dnf5 -y install ${server[@]} ${virt[@]}
fi

if [[ $IMAGE_FLAVOR != "deck" ]]; then
  dnf5 -y swap ublue-update uupd
fi