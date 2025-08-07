#!/usr/bin/env bash

set -ouex pipefail

if [[ $IMAGE_FLAVOR =~ "main" ]]; then
  # disable AMD auto-brightness/veri-bright/panel_power_savings/whatever
  cat <<EOF >>/usr/lib/bootc/kargs.d/99-abmlevel.toml
kargs = ["amdgpu.abmlevel=0"]
EOF
fi