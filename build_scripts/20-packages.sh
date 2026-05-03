#!/usr/bin/bash

set -ouex pipefail

copr_install_isolated() {
  local copr_name="$1"
  shift
  local packages=("$@")

  repo_id="copr:copr.fedorainfracloud.org:${copr_name//\//:}"

  echo "Installing ${packages[*]} from COPR $copr_name (isolated)"

  dnf5 -y copr enable "$copr_name"
  dnf5 -y copr disable "$copr_name"
  dnf5 -y install --enablerepo="$repo_id" "${packages[@]}"
}

third_party_install_isolated() {
  local repo_url="$1"
  local repo_id="$2"
  shift 2
  local packages=("$@")

  echo "Installing ${packages[*]} from $repo_id (isolated)"

  dnf config-manager addrepo --from-repofile="$repo_url"
  dnf config-manager setopt "$repo_id".enabled=0
  dnf -y install --enablerepo="$repo_id" "${packages[@]}"
}


shared() {
  packages=(
    "bat"
    "btop"
    "dua-cli"
    "entr"
    "etckeeper"
    "evtest"
    "fail2ban"
    "gh"
    "netcat"
    "nmap"
    "osbuild-selinux"
    "p7zip"
    "p7zip-plugins"
    "picocom"
    "podman-compose"
    "powertop"
    "ramalama"
    "rar"
    "renameutils"
    "shellcheck"
    "strace"
    "unzip"
    "zsh"
  )

  dnf5 -y install "${packages[@]}"

  third_party_install_isolated "https://pkgs.tailscale.com/stable/fedora/tailscale.repo" "tailscale-stable" \
    "tailscale"

  third_party_install_isolated "https://download.docker.com/linux/fedora/docker-ce.repo" "docker-ce-stable" \
    "docker-ce" \
    "docker-ce-cli" \
    "docker-compose-plugin"

  copr_install_isolated "ublue-os/packages" \
    "uupd"
}


virt() {
  packages=(
    "guestfs-tools"
    "libvirt"
    "virt-install"
  )

  dnf5 -y install "${packages[@]}"
}


server() {
  packages=(
    "https://github.com/trapexit/mergerfs/releases/download/2.41.1/mergerfs-2.41.1-1.fc43.x86_64.rpm"
    "snapraid"
  )

  dnf5 -y install "${packages[@]}"
}


gui() {
  packages=(
    "alacritty"
    "ddccontrol"
    "plasma-wallpapers-dynamic"
    "virt-manager"
    "virt-viewer"
    "wireshark"
  )

  dnf5 -y install "${packages[@]}"

  third_party_install_isolated "https://packages.microsoft.com/yumrepos/vscode/config.repo" "vscode-yum" \
    "code"

  copr_install_isolated "lizardbyte/beta" \
    "Sunshine"
}


shared

if [[ $IMAGE_FLAVOR =~ "main" ]]; then
  gui
  virt
elif [[ $IMAGE_FLAVOR =~ "deck" ]]; then
  gui
elif [[ $IMAGE_FLAVOR =~ "cli" ]]; then
  server
  virt
fi
