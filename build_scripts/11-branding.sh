#!/usr/bin/bash

set -ouex pipefail

# kde about dialog
case $IMAGE_FLAVOR in
  main*)
    VARIANT="Desktop" ;;
  deck*)
    VARIANT="Handheld" ;;
  cli*)
    VARIANT="Server" ;;
  *)
    VARIANT="" ;;
esac

cat >/etc/xdg/kcm-about-distrorc <<EOF
[General]
LogoPath=/usr/share/pixmaps/system-logo-white.png
Name=Pulsar
Website=https://github.com/${IMAGE_VENDOR}/pulsar
Variant=$VARIANT
EOF

# logo branding
find /usr/share/pixmaps \( -name 'fedora*.png' -o -name 'fedora*.svg' \) -exec rm -f '{}' \;
cp -Prf /tmp/branding_files/. /

# deck start/suspend videos
# TODO: make my own?
sed -i 's/\[.*bazzite_novideo.*\]/false/' /usr/bin/bazzite-steam || true

# unbrand fetch
# TODO: make own logo/colors
rm -f /etc/profile.d/bazzite-neofetch.sh