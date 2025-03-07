#!/usr/bin/bash

set -ouex pipefail

dnf5 -y copr enable ublue-os/packages

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
  "https://github.com/trapexit/mergerfs/releases/download/2.40.2/mergerfs-2.40.2-1.fc41.x86_64.rpm"
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

if [[ $IMAGE_FLAVOR =~ "main" ]]; then
  dnf5 -y install ${virt[@]} ${gui[@]}
elif [[ $IMAGE_FLAVOR =~ "deck" ]]; then
  dnf5 -y install ${gui[@]}
elif [[ $IMAGE_FLAVOR =~ "cli" ]]; then
  dnf5 -y install ${server[@]} ${virt[@]}
fi

if [[ ! $IMAGE_FLAVOR =~ "deck" ]]; then
  dnf5 -y swap ublue-update uupd
fi